param(
    [Parameter(Mandatory)] [string]$Top,      # entity to use as simulation top
    [string]$LabDir = (Get-Location).Path,    # lab folder containing synthesis/ and sim/
    [string]$VivadoBin = "C:\dev\Xilinx\Vivado\2018.3\bin",
    [switch]$Gui                              # open the xsim GUI instead of running in batch
)

$ErrorActionPreference = "Stop"

# Keep Vivado's generated junk (xsim.dir, logs, .pb, .jou) out of the source folders
$build = Join-Path $LabDir "build"
New-Item -ItemType Directory -Force $build | Out-Null
Push-Location $build
try {
    # Compile order: synthesis/ first, then sim/, alphabetical within each
    $sources = @(
        Get-ChildItem (Join-Path $LabDir "synthesis") -Filter *.vhd
        Get-ChildItem (Join-Path $LabDir "sim") -Filter *.vhd
    ) | ForEach-Object FullName

    Write-Host "== xvhdl: analyzing $($sources.Count) files" -ForegroundColor Cyan
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
