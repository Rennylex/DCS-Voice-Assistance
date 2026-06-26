param(
    [string]$Phrase = "Ready Precontact",
    [string]$Key = "F1",
    [double]$ConfidenceThreshold = 0.70
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Speech
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public static class DcsKeyboard {
    const uint KEYEVENTF_KEYUP = 0x0002;
    const byte VK_F1 = 0x70;
    const byte F1_SCAN_CODE = 0x3B;

    [DllImport("user32.dll")]
    static extern void keybd_event(byte virtualKey, byte scanCode, uint flags, UIntPtr extraInfo);

    [DllImport("user32.dll")]
    static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    public static void PressFunctionKey(int number) {
        if (number < 1 || number > 6) {
            throw new ArgumentOutOfRangeException("number", "Only F1 through F6 are supported.");
        }

        byte virtualKey = (byte)(VK_F1 + number - 1);
        byte scanCode = (byte)(F1_SCAN_CODE + number - 1);
        keybd_event(virtualKey, scanCode, 0, UIntPtr.Zero);
        Thread.Sleep(100);
        keybd_event(virtualKey, scanCode, KEYEVENTF_KEYUP, UIntPtr.Zero);
    }

    public static uint GetForegroundProcessId() {
        uint processId;
        GetWindowThreadProcessId(GetForegroundWindow(), out processId);
        return processId;
    }
}
"@

$commands = @{
    "Ready Precontact"       = "F1"
    "Vector to bullseye"     = "F1"
    "Vector to home plate"   = "F2"
    "Vector to tanker"       = "F3"
    "Request bogey dope"     = "F4"
    "Request picture"        = "F5"
    "Declare"                = "F6"
}
$commands[$Phrase] = $Key

$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$recognizer.SetInputToDefaultAudioDevice()

$choices = New-Object System.Speech.Recognition.Choices
foreach ($commandPhrase in $commands.Keys) {
    $choices.Add($commandPhrase) | Out-Null
}

$grammarBuilder = New-Object System.Speech.Recognition.GrammarBuilder
$grammarBuilder.Culture = $recognizer.RecognizerInfo.Culture
$grammarBuilder.Append($choices)

$grammar = New-Object System.Speech.Recognition.Grammar($grammarBuilder)
$grammar.Name = "DCSVoiceCommands"
$recognizer.LoadGrammar($grammar)

Register-ObjectEvent -InputObject $recognizer -EventName SpeechRecognized -SourceIdentifier DCSVoiceCommandRecognized | Out-Null

Write-Host "DCS Voice Assist is listening."
Write-Host "Voice commands:"
$commands.GetEnumerator() | Sort-Object Value, Key | ForEach-Object {
    Write-Host "  '$($_.Key)' -> $($_.Value)"
}
Write-Host "Confidence threshold: $ConfidenceThreshold"
Write-Host "Keep this window open, then switch back to DCS so it is the active window."
Write-Host "Press Ctrl+C to stop."

$recognizer.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)

try {
    while ($true) {
        $event = Wait-Event -SourceIdentifier DCSVoiceCommandRecognized -Timeout 1
        if ($null -eq $event) {
            continue
        }

        try {
            $result = $event.SourceEventArgs.Result
            $matchedKey = $commands[$result.Text]
            if ($null -ne $matchedKey -and $result.Confidence -ge $ConfidenceThreshold) {
                $keyNumber = [int]$matchedKey.Substring(1)
                $foregroundPid = [DcsKeyboard]::GetForegroundProcessId()
                $foregroundName = (Get-Process -Id $foregroundPid -ErrorAction SilentlyContinue).ProcessName
                if ([string]::IsNullOrWhiteSpace($foregroundName)) {
                    $foregroundName = "unknown"
                }

                $timestamp = Get-Date -Format "HH:mm:ss"
                Write-Host "[$timestamp] Recognized '$($result.Text)' confidence=$([Math]::Round($result.Confidence, 2)); sending $matchedKey to foreground process '$foregroundName'"
                [DcsKeyboard]::PressFunctionKey($keyNumber)
            }
        }
        catch {
            Write-Host "Command failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        finally {
            Remove-Event -EventIdentifier $event.EventIdentifier -ErrorAction SilentlyContinue
        }
    }
}
finally {
    $recognizer.RecognizeAsyncCancel()
    $recognizer.Dispose()
    Unregister-Event -SourceIdentifier DCSVoiceCommandRecognized -ErrorAction SilentlyContinue
    Get-Event -SourceIdentifier DCSVoiceCommandRecognized -ErrorAction SilentlyContinue | Remove-Event -ErrorAction SilentlyContinue
}
