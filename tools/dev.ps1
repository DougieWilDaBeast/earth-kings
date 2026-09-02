# Dev entry points. Godot is not on PATH, and the flags are long enough that
# typing them by hand is where the mistakes come from.
#
#   . .\tools\dev.ps1          # load these into the session
#   bench --scene=world --at=gate --level=6 --play
#   shot party --level=6 --gold=800
#   suite                      # every smoke test, one line each
#   suite walk                 # just one

$script:Godot = "C:\Dev\Godot_v4.7.2-stable_win64_console.exe"
$script:Project = "C:\Dev\earth-kings"
$script:Suites = @("battle", "world", "walk", "area", "skein", "wishlist")


function Join-Flags {
    <#  PowerShell reads `--stores=a,b` in argument mode as two arguments. Put
        anything that is not a flag back onto the flag it was split off. #>
    param([object[]]$Raw)
    $out = @()
    foreach ($item in @($Raw)) {
        $text = [string]$item
        if ($text.StartsWith('--') -or $out.Count -eq 0) { $out += $text }
        else { $out[-1] = "$($out[-1]),$text" }
    }
    return $out
}


function bench {
    <#  Boot into a scene. Add --play or --shot to get a window. #>
    $rest = Join-Flags $args
    $windowed = @($rest | Where-Object { $_ -like '--play*' -or $_ -like '--shot*' }).Count -gt 0
    $argv = @('--path', $script:Project)
    if (-not $windowed) { $argv += '--headless' }
    $argv += @('res://tests/bench.tscn', '--') + $rest
    & $script:Godot @argv
}


function shot {
    <#  Photograph a scene: shot party --level=6 #>
    param([Parameter(Mandatory)][string]$Scene)
    $argv = @(
        '--path', $script:Project, 'res://tests/bench.tscn', '--',
        "--scene=$Scene", "--shot=$Scene"
    ) + (Join-Flags $args)
    & $script:Godot @argv
}


function suite {
    <#  Run every smoke test, or just the named ones. One line per suite. #>
    $names = if ($args.Count) { $args } else { $script:Suites }
    foreach ($name in $names) {
        $out = & $script:Godot --path $script:Project --headless `
            "res://tests/${name}_smoke_test.tscn" 2>&1
        $verdict = ($out | Select-String -Pattern 'PASS|FAIL|failure|victory') -join ' | '
        if (-not $verdict) { $verdict = "no verdict — check for a parse error" }
        "{0,-10} {1}" -f $name, $verdict
    }
}


function parsecheck {
    <#  Import and compile everything; prints only what is broken. #>
    $out = & $script:Godot --path $script:Project --headless --editor --quit 2>&1
    $bad = $out | Select-String -Pattern "SCRIPT ERROR|Parse Error|Compile Error"
    if ($bad) { $bad | Select-Object -First 20 } else { "clean" }
}

Write-Host "dev: bench / shot / suite / parsecheck" -ForegroundColor DarkGray
