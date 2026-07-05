# Simple simulation script for Windows (Icarus Verilog)
# Compile with top-level file which includes all submodules
iverilog -o simv i2c_master.v i2c_master_tb.v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
vvp simv
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (Test-Path -Path i2c_master_tb.vcd) {
    Write-Host "Waveform saved: i2c_master_tb.vcd"
} else {
    Write-Host "No waveform generated."
}
