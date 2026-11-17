<#
.SYNOPSIS
    Maps an 8BitDo controller (or any X-input / SDL gamepad) to a PCSX2 port as a DualShock 2.

.DESCRIPTION
    Rewrites the [PadN] section of PCSX2.ini with a full DualShock 2 mapping
    (buttons, sticks, pressure triggers, rumble) bound to an SDL device, and
    enables the SDL input source. A timestamped backup of the ini is made first.

    Close PCSX2 before running: it rewrites PCSX2.ini when it exits.

.PARAMETER Ini
    Path to PCSX2.ini. If omitted, the script looks in the standard location
    (Documents\PCSX2\inis) and in a portable install next to pcsx2-qt.exe.

.PARAMETER Port
    PCSX2 controller port to configure (1 or 2). Default: 1.

.PARAMETER SdlIndex
    SDL device index. Use 1, 2, ... if PCSX2 lists your pad as SDL-1, SDL-2, ...
    Default: 0.

.PARAMETER PortableDir
    Folder of a portable PCSX2 install (the one containing pcsx2-qt.exe).

.EXAMPLE
    .\fix-8bitdo-pad.ps1

.EXAMPLE
    .\fix-8bitdo-pad.ps1 -Port 2 -SdlIndex 1

.EXAMPLE
    .\fix-8bitdo-pad.ps1 -Ini "D:\Emu\PCSX2\inis\PCSX2.ini"
#>
[CmdletBinding()]
param(
    [string]$Ini,
    [ValidateSet(1, 2)][int]$Port = 1,
    [ValidateRange(0, 15)][int]$SdlIndex = 0,
    [string]$PortableDir
)

$ErrorActionPreference = 'Stop'

function Find-PcsxIni {
    $candidates = @()
    if ($PortableDir) { $candidates += Join-Path $PortableDir 'inis\PCSX2.ini' }

    # Standard install (handles Documents redirected to OneDrive etc.)
    $docs = [Environment]::GetFolderPath('MyDocuments')
    $candidates += Join-Path $docs 'PCSX2\inis\PCSX2.ini'

    # Portable install: look next to a running or PATH-resolvable pcsx2-qt.exe
    $exe = (Get-Command pcsx2-qt -ErrorAction SilentlyContinue).Source
    if ($exe) { $candidates += Join-Path (Split-Path $exe) 'inis\PCSX2.ini' }

    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    return $null
}

if (-not $Ini) { $Ini = Find-PcsxIni }
if (-not $Ini -or -not (Test-Path $Ini)) {
    Write-Error "PCSX2.ini not found. Run PCSX2 once to create it, or pass -Ini <path> / -PortableDir <folder>."
}

if (Get-Process -Name pcsx2-qt, pcsx2 -ErrorAction SilentlyContinue) {
    Write-Error "PCSX2 is running. Close it and run this script again."
}

$backup = "$Ini.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item $Ini $backup
Write-Host "Backup: $backup"

$d = "SDL-$SdlIndex"
$section = @"
[Pad$Port]
Type = DualShock2
InvertL = 0
InvertR = 0
Deadzone = 0
AxisScale = 1.33
LargeMotorScale = 1
SmallMotorScale = 1
ButtonDeadzone = 0
PressureModifier = 0.5
Up = $d/DPadUp
Right = $d/DPadRight
Down = $d/DPadDown
Left = $d/DPadLeft
Triangle = $d/FaceNorth
Circle = $d/FaceEast
Cross = $d/FaceSouth
Square = $d/FaceWest
Select = $d/Back
Start = $d/Start
L1 = $d/LeftShoulder
L2 = $d/+LeftTrigger
R1 = $d/RightShoulder
R2 = $d/+RightTrigger
L3 = $d/LeftStick
R3 = $d/RightStick
LUp = $d/-LeftY
LRight = $d/+LeftX
LDown = $d/+LeftY
LLeft = $d/-LeftX
RUp = $d/-RightY
RRight = $d/+RightX
RDown = $d/+RightY
RLeft = $d/-RightX
Analog = $d/Guide
LargeMotor = $d/LargeMotor
SmallMotor = $d/SmallMotor

"@ -replace '\r?\n', "`r`n"

$text = [IO.File]::ReadAllText($Ini)

# Replace the whole [PadN] section (up to the next [section] or end of file).
$rx = "(?ms)^\[Pad$Port\]\r?\n.*?(?=^\[|\z)"
if ([regex]::IsMatch($text, $rx)) {
    $text = [regex]::Replace($text, $rx, { param($m) $section })
} else {
    $text = $text.TrimEnd() + "`r`n`r`n" + $section
}

# Make sure the SDL input source is on.
$text = [regex]::Replace($text, '(?m)^(SDL\s*=\s*)false', '${1}true')

# Write back without a BOM.
[IO.File]::WriteAllText($Ini, $text, (New-Object Text.UTF8Encoding $false))
Write-Host "Port $Port is now a DualShock 2 mapped to $d ($Ini). Start PCSX2 and test."
