$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$root = (Get-Location).Path
$release = Join-Path $root 'release'
$work = Join-Path $root 'build-installer'
$app = Join-Path $release 'app'
function Run-Checked($exe, [string[]]$arguments) {
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed ($LASTEXITCODE): $exe" }
}
foreach ($p in @($release,$work)) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }
New-Item -ItemType Directory -Force -Path $app,$work | Out-Null
Expand-Archive -LiteralPath (Join-Path $root 'LEMATZIUM-1.3.3.zip') -DestinationPath $work -Force
$source = @(Get-ChildItem $work -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'launcher\lematzium_suite_launcher.py') })
if ($source.Count -ne 1) { throw 'Unexpected archive structure' }
$source = $source[0].FullName
Copy-Item -Path (Join-Path $source '*') -Destination $app -Recurse -Force
# Ensure personal settings never enter a public installer.
$prefs = Join-Path $app 'launcher\lematzium_suite_launcher_prefs.json'
if (Test-Path $prefs) {
    $json = Get-Content -LiteralPath $prefs -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($json.PSObject.Properties.Name -contains 'gemini_api_key') { $json.gemini_api_key = '' }
    [IO.File]::WriteAllText($prefs, ($json | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
}
$hostPython = (Get-Command python.exe).Source
$pythonHome = (& $hostPython -c "import sys; print(sys.base_prefix)").Trim()
Run-Checked $hostPython @('-m','pip','install','numpy','pandas','matplotlib','openpyxl','pyxlsb','xlrd','pillow','python-docx','pypdf','PyPDF2','PySide6','google-genai','sounddevice','pygame')
$runtime = Join-Path $app 'runtime'
& robocopy $pythonHome $runtime /E /XD __pycache__ /XF '*.pyc' /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) { throw 'Failed to copy private Python runtime' }
$python = Join-Path $runtime 'python.exe'
$env:PYTHONHOME = $runtime
$env:PYTHONNOUSERSITE = '1'
$env:PYTHONPATH = ''
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:LEMATZIUM_PYTHON = $python
$env:LEMATZIUM_INSTALLED = '1'
# Avoid developer shortcut creation in the installed edition; keep module/theme logic unchanged.
$launcher = Join-Path $app 'launcher\lematzium_suite_launcher.py'
$code = [IO.File]::ReadAllText($launcher)
$old = 'if not _is_frozen_app():' + [Environment]::NewLine + '            try:'
$code = $code -replace 'if not _is_frozen_app\(\):(?=\r?\n            try:\r?\n                from dev_shortcut_sync)', 'if not _is_frozen_app() and not os.environ.get("LEMATZIUM_INSTALLED"):'
[IO.File]::WriteAllText($launcher,$code,(New-Object Text.UTF8Encoding($false)))
# Run GUI child processes without opening a console window, while keeping normal Tk windows.
$launchRuntime = Join-Path $app 'launcher\launch_runtime.py'
$code = [IO.File]::ReadAllText($launchRuntime)
$code = $code.Replace('getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)', 'getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0) | (getattr(subprocess, "CREATE_NO_WINDOW", 0) if os.environ.get("LEMATZIUM_INSTALLED") else 0)')
[IO.File]::WriteAllText($launchRuntime,$code,(New-Object Text.UTF8Encoding($false)))
# Test the private interpreter and original analysis modules.
Run-Checked $python @('-c','import sys, pathlib, tkinter, numpy, pandas, matplotlib, docx, pypdf, openpyxl, pyxlsb, xlrd, PIL, PySide6, google.genai, sounddevice, pygame; assert pathlib.Path(sys.prefix).resolve() == pathlib.Path(sys.executable).resolve().parent; r=tkinter.Tk(); r.withdraw(); r.update(); r.destroy(); print("Private runtime OK")')
Push-Location $app
try {
    Run-Checked $python @((Join-Path $source 'tools\validate_refactor.py'))
    Run-Checked $python @('modules\module_tensile_unified\validate_unified_module.py')
    Run-Checked $python @('modules\module_4_traccion_plasticos\validate_traccion_plasticos.py')
    Run-Checked $python @('modules\module_3_ai_assistant\validate_ai_assistant.py')
    Run-Checked $python @('-c','import sys; sys.path[:0]=["launcher","modules","modules/module_3_ai_assistant","SECRETO_LEMATZIUM"]; import lematzium_suite_launcher, uncertainty_editor, lematzium_ai_assistant.ui, lematzium_minijuego_retro.app; print("Hub, uncertainty, assistant and game import OK")')
} finally { Pop-Location }
Get-ChildItem $app -Directory -Recurse -Filter '__pycache__' | Sort-Object FullName -Descending | Remove-Item -Recurse -Force
# Compile a small native Windows GUI bootstrapper. The original Python source stays intact.
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (!(Test-Path $csc)) { throw 'Windows C# compiler missing' }
$icon = Join-Path $app 'build_assets\icons\lematzium_default.ico'
$out = Join-Path $app 'LEMATZIUM.exe'
Run-Checked $csc @('/nologo','/target:winexe','/platform:x64','/reference:System.Windows.Forms.dll',"/win32icon:$icon","/out:$out",(Join-Path $PSScriptRoot 'Launcher.cs'))
# Inno Setup may already be installed on the runner.
$iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
if (!(Test-Path $iscc)) {
    Run-Checked 'choco.exe' @('install','innosetup','-y','--no-progress')
}
if (!(Test-Path $iscc)) { throw 'Inno Setup compiler missing' }
Run-Checked $iscc @((Join-Path $PSScriptRoot 'LEMATZIUM.iss'))
$setup = Join-Path $release 'LEMATZIUM_Setup_1.3.3.exe'
if (!(Test-Path $setup)) { throw 'Installer not found' }
$hash = (Get-FileHash -Algorithm SHA256 $setup).Hash.ToLowerInvariant()
[IO.File]::WriteAllText("$setup.sha256", "$hash  LEMATZIUM_Setup_1.3.3.exe"+[Environment]::NewLine)
Write-Host "Installer ready: $setup"
