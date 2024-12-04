# Imports
. .\Scripts\Diagnostics\Simulate_Usage.ps1

function Invoke-RunForever {
    while ($true) {
        Start-Simulate_Usage
    }

    # Uncomment below to just run once for testing
    # Start-Simulate_Usage
}

Invoke-RunForever