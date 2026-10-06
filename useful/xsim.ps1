param(
    [Parameter(Mandatory)] [string]$Top,      # entity to use as simulation top
    [string]$LabDir = (Get-Location).Path,    # lab folder containing synthesis/ and sim/
    [string]$VivadoBin = "C:\dev\Xilinx\Vivado\2018.3\bin",
    [switch]$Gui                              # open the xsim GUI instead of running in batch
)

$ErrorActionPreference = "Stop"

# Order files so every 'entity work.X' / 'use work.X' target is analyzed
# before the file that references it. Component instantiations bind at
# elaboration, so they don't need ordering.
function Get-CompileOrder([string[]]$Files) {
    $defines = @{}   # unit name -> file that declares it
    $deps    = @{}   # file -> unit names it references in work

    foreach ($f in $Files) {
        $text = [regex]::Replace((Get-Content $f -Raw), '--[^\r\n]*', '')  # strip comments
        foreach ($m in [regex]::Matches($text, '(?im)^\s*(entity|package)\s+(\w+)\s+is\b')) {
            $defines[$m.Groups[2].Value.ToLower()] = $f
        }
        $refs = @()
        foreach ($m in [regex]::Matches($text, '(?i)\b(?:entity|use)\s+work\.(\w+)')) {
            $refs += $m.Groups[1].Value.ToLower()
        }
        $deps[$f] = @($refs | Select-Object -Unique)
    }

    $ordered = [System.Collections.Generic.List[string]]::new()
    $state   = @{}
    function Visit([string]$f) {
        if ($state[$f] -eq 'done') { return }
        if ($state[$f] -eq 'visiting') { throw "Circular dependency involving $f" }
        $state[$f] = 'visiting'
        foreach ($u in $deps[$f]) {
            if ($defines.ContainsKey($u) -and $defines[$u] -ne $f) { Visit $defines[$u] }
        }
        $state[$f] = 'done'
        $ordered.Add($f)
    }
    foreach ($f in $Files) { Visit $f }
    return ,$ordered
}

# Keep Vivado's generated junk (xsim.dir, logs, .pb, .jou) out of the source folders
$build = Join-Path $LabDir "build"
New-Item -ItemType Directory -Force $build | Out-Null
Push-Location $build
try {
    $found = @(
        Get-ChildItem (Join-Path $LabDir "synthesis") -Filter *.vhd
        Get-ChildItem (Join-Path $LabDir "sim") -Filter *.vhd
    ) | ForEach-Object FullName
    $sources = Get-CompileOrder $found

    Write-Host "== xvhdl: analyzing $($sources.Count) files in dependency order" -ForegroundColor Cyan
    & "$VivadoBin\xvhdl.bat" $sources
    if ($LASTEXITCODE -ne 0) { throw "xvhdl failed" }

    Write-Host "== xelab: elaborating work.$Top" -ForegroundColor Cyan
    & "$VivadoBin\xelab.bat" -debug typical "work.$Top" -s "${Top}_sim"
    if ($LASTEXITCODE -ne 0) { throw "xelab failed" }

    Write-Host "== xsim: running ${Top}_sim" -ForegroundColor Cyan
    if ($Gui) {
        $tcl = Join-Path $build "gui.tcl"
        "log_wave -r /`nrun all" | Set-Content $tcl
        & "$VivadoBin\xsim.bat" "${Top}_sim" -gui -tclbatch gui.tcl
    } else {
        & "$VivadoBin\xsim.bat" "${Top}_sim" -runall
    }
    if ($LASTEXITCODE -ne 0) { throw "xsim failed" }
}
finally {
    Pop-Location
}