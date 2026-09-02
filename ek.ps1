# Earth Kings dev launcher.
#
#   .\ek.ps1 test                 run every smoke suite, one line each
#   .\ek.ps1 test walk world      run only those
#   .\ek.ps1 --list=sites         ask the data a question
#   .\ek.ps1 --scene=party --level=6 --shot
#   .\ek.ps1 --scene=world --at=gate --level=6 --play
#
# Godot is not on PATH, and screenshots and --play need a real renderer, so
# --headless is added only when neither was asked for.
#
# Uses $args rather than a param block: binding to [string[]] splits a flag like
# --stores=a,b into two arguments, which loses everything after the comma.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$Flags = @(foreach ($a in $args) {
        # PowerShell parses `--flag=a,b` into a nested array, which would otherwise
        # arrive as only its first element.
        if ($a -is [array]) { $a -join ',' } else { "$a" }
    })

$godot = 'C:\Dev\Godot_v4.7.2-stable_win64_console.exe'
$project = $PSScriptRoot
$suites = @('battle', 'world', 'walk', 'area', 'skein', 'wishlist')

if ($Flags.Count -gt 0 -and $Flags[0] -eq 'test') {
    $wanted = if ($Flags.Count -gt 1) { $Flags[1..($Flags.Count - 1)] } else { $suites }
    $failed = 0
    foreach ($name in $wanted) {
        $out = & $godot --path $project --headless "res://tests/${name}_smoke_test.tscn" 2>&1
        $verdict = ($out | Select-String -Pattern 'PASS|FAIL|failure|victory:') -join ' | '
        if ($verdict -match 'FAIL|failure') { $failed++ }
        '{0,-9} {1}' -f $name, $verdict
    }
    if ($failed -gt 0) { "`n$failed suite(s) failing"; exit 1 }
    exit 0
}

$visual = $Flags | Where-Object { $_ -like '--play*' -or $_ -like '--shot*' }
$mode = if ($visual) { @() } else { @('--headless') }
# Built as one array and splatted: written inline, PowerShell eats the bare `--`
# that Godot needs to know where its own arguments stop.
$argv = @('--path', $project) + $mode + @('res://tests/bench.tscn', '--') + $Flags
& $godot @argv
