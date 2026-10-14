// Browser half of tools/web_smoke.py: plays the exported Web build in headless
// Chromium and fails on anything the console complains about.
//
//   node tools/web_smoke.js <url> <shot dir>
//
// Needs the `playwright` npm package (global is fine: web_smoke.py points
// NODE_PATH at `npm root -g`) and a Chromium it can find, e.g. through
// PLAYWRIGHT_BROWSERS_PATH. The walk is driven from the keyboard wherever it
// can be, so a moved button does not break it:
//   boot -> any key past the title card -> New Game -> four quiz answers ->
//   a life -> the world -> three steps -> Esc menu -> Save Game ->
//   reload -> Continue.
// Prints one JSON line of timings and findings; exits 1 on any failure.

const { chromium } = require('playwright');

const [url, shots] = process.argv.slice(2);
if (!url || !shots) {
  console.error('usage: node tools/web_smoke.js <url> <shot dir>');
  process.exit(2);
}

// Chrome says this until the first click or key, and Godot resumes the audio
// on that first input by itself. It is a warning, but name it so nobody chases it.
const EXPECTED = [/AudioContext was not allowed to start/];
const SAVE_FILE = 'earth-kings.save.json';

(async () => {
  const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  const page = await context.newPage();
  const problems = [];
  const lines = [];
  const t0 = Date.now();
  const since = () => (Date.now() - t0) / 1000;

  page.on('console', (m) => {
    const text = m.text();
    lines.push({ at: since(), type: m.type(), text });
    if (EXPECTED.some((re) => re.test(text))) return;
    if (m.type() === 'error' || /SCRIPT ERROR|^ERROR:|^USER ERROR:/.test(text)) problems.push(`console: ${text}`);
  });
  page.on('pageerror', (e) => problems.push(`page: ${e.message}`));
  page.on('requestfailed', (r) => problems.push(`request failed: ${r.url()}`));
  page.on('response', (r) => { if (r.status() >= 400) problems.push(`HTTP ${r.status()}: ${r.url()}`); });

  const waitFor = async (re, timeout, what) => {
    const end = Date.now() + timeout;
    while (Date.now() < end) {
      const hit = lines.find((l) => re.test(l.text));
      if (hit) return hit.at;
      await page.waitForTimeout(200);
    }
    throw new Error(`timed out after ${timeout / 1000}s waiting for ${what}`);
  };
  const press = async (key, settle = 1200) => {
    await page.keyboard.down(key);
    await page.waitForTimeout(120);
    await page.keyboard.up(key);
    await page.waitForTimeout(settle);
  };
  const shot = (name) => page.screenshot({ path: `${shots}/${name}.png` });
  const saveOnDisk = () => page.evaluate((file) => new Promise((resolve) => {
    const open = indexedDB.open('/userfs');
    open.onerror = () => resolve(false);
    open.onsuccess = () => {
      const db = open.result;
      if (!db.objectStoreNames.contains('FILE_DATA')) return resolve(false);
      const keys = db.transaction('FILE_DATA').objectStore('FILE_DATA').getAllKeys();
      keys.onsuccess = () => resolve(keys.result.some((k) => String(k).endsWith(file)));
      keys.onerror = () => resolve(false);
    };
  }), SAVE_FILE);

  const result = {};
  try {
    await page.goto(url);
    result.boot_s = await waitFor(/^Earth Kings: new run/, 60000, 'the game to boot');
    await page.waitForTimeout(2500);
    await shot('01-title-card');

    await press('Space', 2500);
    await shot('02-title');
    await press('Enter', 2000); // New Game: focused when there is no save
    for (let i = 0; i < 4; i++) await press('Enter', 1200); // four quiz answers
    await shot('03-quiz-done');
    const picked = Date.now();
    await press('Enter', 2000); // the life the quiz found, or "Show me all sixteen"
    await shot('04-character-select');
    await press('Enter', 500); // the focused life
    const started = await waitFor(/new run, seed \d+, lead '[a-z_]+'/, 60000, 'a run to start');
    result.world_s = +(started - (picked - t0) / 1000).toFixed(2);
    await page.waitForTimeout(3000);
    await shot('05-world');

    // The arrival lines: a click on the dialogue box moves them on.
    for (let i = 0; i < 4; i++) { await page.mouse.click(640, 660); await page.waitForTimeout(600); }
    for (const key of ['KeyD', 'KeyD', 'KeyS']) await press(key, 900);
    await shot('06-walked');

    await press('Escape', 1200);
    await shot('07-menu');
    await page.mouse.click(640, 152); // Save Game, top of the system menu
    await page.waitForTimeout(2000);
    await shot('08-saved');
    result.saved = await saveOnDisk();
    if (!result.saved) problems.push(`no ${SAVE_FILE} in IndexedDB /userfs after Save Game`);

    lines.length = 0;
    await page.reload();
    await waitFor(/^Earth Kings: new run/, 60000, 'the game to boot again');
    await page.waitForTimeout(1500);
    await press('Space', 2500);
    await shot('09-title-with-save');
    await press('Enter', 5000); // Continue: focused when there is a save
    await shot('10-continued');
  } catch (e) {
    problems.push(e.message);
    await shot('99-failed').catch(() => {});
  }
  await browser.close();
  result.problems = problems;
  console.log(JSON.stringify(result));
  process.exit(problems.length ? 1 : 0);
})();
