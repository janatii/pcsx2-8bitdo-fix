# fix-8bitdo-pad

A PowerShell script that sets up an **8BitDo controller** (or any X-input / SDL gamepad) as a
**DualShock 2** in [PCSX2](https://pcsx2.net), by writing a complete mapping into `PCSX2.ini`.

Handy when PCSX2 doesn't pick up the pad, the automatic mapping is wrong, or buttons are swapped.

## What it does

- Backs up `PCSX2.ini` (`PCSX2.ini.bak-YYYYMMDD-HHMMSS`)
- Replaces the `[PadN]` section with a full DualShock 2 mapping: D-pad, face buttons,
  shoulders, pressure-sensitive triggers, both sticks, L3/R3, Analog (Guide button) and rumble
- Turns on the SDL input source

## Requirements

- Windows with PowerShell 5.1 or later
- PCSX2 (Qt version, 1.7+ / 2.x), started at least once so `PCSX2.ini` exists
- 8BitDo controller in **X-input mode** (on most models: hold **X** while powering on;
  check your model's manual)

## Usage

1. Close PCSX2 (it overwrites `PCSX2.ini` when it exits).
2. Run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\fix-8bitdo-pad.ps1
   ```

3. Start PCSX2 and test.

### Options

| Parameter      | Default        | Description |
|----------------|----------------|-------------|
| `-Ini`         | auto-detected  | Path to `PCSX2.ini` |
| `-PortableDir` | –              | Folder of a portable PCSX2 install (contains `pcsx2-qt.exe`) |
| `-Port`        | `1`            | Controller port to configure (`1` or `2`) |
| `-SdlIndex`    | `0`            | SDL device index; use `1`, `2`… if PCSX2 shows the pad as `SDL-1`, `SDL-2`… |

Examples:

```powershell
.\fix-8bitdo-pad.ps1 -Port 2 -SdlIndex 1
.\fix-8bitdo-pad.ps1 -PortableDir "D:\Emulators\PCSX2"
.\fix-8bitdo-pad.ps1 -Ini "D:\Emulators\PCSX2\inis\PCSX2.ini"
```

If no `-Ini` is given, the script looks in `Documents\PCSX2\inis\PCSX2.ini`
(including Documents redirected to OneDrive) and next to `pcsx2-qt.exe` if it is on `PATH`.

## Undo

Copy the backup over `PCSX2.ini`:

```powershell
Copy-Item "$([Environment]::GetFolderPath('MyDocuments'))\PCSX2\inis\PCSX2.ini.bak-<timestamp>" `
          "$([Environment]::GetFolderPath('MyDocuments'))\PCSX2\inis\PCSX2.ini"
```
