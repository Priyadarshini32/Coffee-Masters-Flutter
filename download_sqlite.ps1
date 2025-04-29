$sqlite3Dir = "web/sqlite3"
$sqlite3WasmUrl = "https://raw.githubusercontent.com/simolus3/sqlite3.dart/master/packages/sqlite3_common_ffi_web/lib/src/worker/sqlite3.wasm"

# Create directory if it doesn't exist
if (-not (Test-Path $sqlite3Dir)) {
    New-Item -ItemType Directory -Path $sqlite3Dir
}

# Download WASM file
Write-Host "Downloading SQLite WASM file..."
Invoke-WebRequest -Uri $sqlite3WasmUrl -OutFile "$sqlite3Dir/sqlite3.wasm"

# Verify file exists
if (Test-Path "$sqlite3Dir/sqlite3.wasm") {
    Write-Host "SQLite WASM file downloaded successfully!"
} else {
    Write-Host "Error: SQLite WASM file was not downloaded successfully"
} 