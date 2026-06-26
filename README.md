# DCS Voice Assist
# Proudly presented by RennyLex
A small local voice-control helper for DCS on Windows. It uses Windows' built-in `System.Speech` recognition and sends function-key input to the active DCS window.

## Voice commands

| Say | Key |
| --- | --- |
| `Ready Precontact` | `F1` |
| `Vector to bullseye` | `F1` |
| `Vector to home plate` | `F2` |
| `Vector to tanker` | `F3` |
| `Request bogey dope` | `F4` |
| `Request picture` | `F5` |
| `Declare` | `F6` |

## Run

Double-click `Start-DCSVoiceAssist.bat`, then switch back to DCS. DCS must be the foreground window when a command is recognized.

Leave the console window open while playing. Press `Ctrl+C` in the console to stop.

Currently it supports frequently used functions in the AWACS and Tanker radio section--the ones you wanna accomplish without moving your hands off the HOTAS too often, so before you call out your actions, make sure you are in those radio sections first.

## Notes

- No Python packages or cloud service are required.
- If DCS is running as administrator, run `Start-DCSVoiceAssist.bat` as administrator too.
- Adjust `ConfidenceThreshold` in `DCSVoiceAssist.ps1` if recognition is too strict or too permissive.
