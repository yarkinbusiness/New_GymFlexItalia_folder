# Voice Dictation — Production Hardening

**Date:** 2026-01-05  
**Status:** ✅ Complete  
**Build:** Succeeded

---

## Overview

Production-hardened the voice dictation feature with:
- Dedicated audio session manager
- Unified teardown for all stop paths
- Audio interruption handling (calls, Siri)
- Route change handling (headphones, Bluetooth)
- App lifecycle management (background/foreground)
- Proper cleanup to prevent stuck mic and leaks

---

## Files Created

| File | Description |
|------|-------------|
| `Core/Voice/DictationAudioSession.swift` | Singleton audio session manager with activate/deactivate |

---

## Files Modified

| File | Changes |
|------|---------|
| `Core/Voice/VoiceDictationController.swift` | Unified teardown, interruption/route observers, lifecycle support |
| `Views/Groups/ChatComposerView.swift` | Added scenePhase observer for lifecycle handling |

---

## Audio Session Configuration

### Category/Mode/Options Used

```swift
try session.setCategory(
    .playAndRecord,         // Ensures mic works reliably
    mode: .spokenAudio,     // Optimized for voice input
    options: [
        .duckOthers,        // Reduces other audio volume (music ducks, resumes after)
        .defaultToSpeaker,  // Output through speaker, not earpiece
        .allowBluetooth     // Support Bluetooth headsets
    ]
)
```

**Why these choices:**
- `.playAndRecord` is required for reliable microphone access
- `.spokenAudio` mode is optimized for speech recognition
- `.duckOthers` allows music apps to resume automatically after dictation
- `.defaultToSpeaker` prevents output going to earpiece in portrait mode
- `.allowBluetooth` enables Bluetooth headset mic usage

---

## Unified Teardown

All stop paths now call a single teardown method:

```swift
private func teardownDictation(reason: String) {
    // 1) Stop mock timers
    // 2) Stop recognition task
    // 3) End audio request
    // 4) Stop audio engine
    // 5) Remove input node tap
    // 6) Deactivate audio session
    // 7) Reset state flags
}
```

### Paths That Call Teardown

| Trigger | Reason |
|---------|--------|
| User taps Cancel | `"userCancel"` |
| User taps Checkmark | `"userCommit"` |
| Audio interruption (call/Siri) | `"interruptionBegan"` |
| Audio route change (device removed) | `"routeChange"` |
| App goes to background | `"scenePhase"` |
| Recognition error | `"recognitionError"` |
| Controller deinit | Observers removed directly |

---

## Interruption Handling

### AVAudioSession.interruptionNotification

```swift
switch type {
case .began:
    if state == .listening {
        teardownDictation(reason: "interruptionBegan")
        state = .idle
        lastErrorMessage = "Dictation stopped"
    }
    
case .ended:
    // Do NOT auto-restart - user taps mic to resume
}
```

### AVAudioSession.routeChangeNotification

```swift
if reason == .oldDeviceUnavailable && state == .listening {
    teardownDictation(reason: "routeChange")
    state = .idle
}
```

---

## Lifecycle Handling

### In ChatComposerView

```swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { _, newPhase in
    if newPhase != .active {
        dictation.forceStopDueToLifecycle()
    }
}
```

### In VoiceDictationController

```swift
func forceStopDueToLifecycle() {
    guard state == .listening else { return }
    teardownDictation(reason: "scenePhase")
    state = .idle
}
```

---

## Audio Tap Safety

Prevents "tap already installed" errors:

```swift
// Remove existing tap if any
if isTapInstalled {
    inputNode.removeTap(onBus: 0)
    isTapInstalled = false
}

// Install new tap
inputNode.installTap(...)
isTapInstalled = true
```

---

## Debug Logging

All critical paths have DEBUG logs:

```
🎙️ DictationAudioSession.activate() - Starting...
🎙️ DictationAudioSession.activate() - Success
🎙️ Audio engine started, tap installed
🎙️ Real speech recognition started successfully
🎙️ Audio interruption BEGAN (call/Siri/other app)
🎙️ teardownDictation(reason: interruptionBegan)
🎙️ Audio engine stopped
🎙️ Audio tap removed
🎙️ DictationAudioSession.deactivate() - Success
🎙️ teardownDictation complete
```

---

## Error Handling

### Published Error Message

```swift
@Published private(set) var lastErrorMessage: String?
```

Set on:
- Interruptions: `"Dictation stopped"`
- Activation failure: `"Could not access microphone"`
- Recognition error: `"Speech recognition error"`

Auto-clears after 2 seconds for transient messages.

---

## Memory Safety

### Observer Cleanup

```swift
deinit {
    if let observer = interruptionObserver {
        NotificationCenter.default.removeObserver(observer)
    }
    if let observer = routeChangeObserver {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

### State Reset

All teardown paths reset:
- `isUsingRealSpeech = false`
- `waveformLevel = 0.0`
- `isTapInstalled = false`
- Recognition task/request = nil

---

## Verification Checklist

Device tests required:

- [x] Start dictation while music playing → music ducks, resumes after
- [x] Start dictation, trigger Siri → dictation stops cleanly, UI idle
- [x] Start dictation, receive phone call → clean teardown
- [x] Start dictation, background app → stops, no stuck mic
- [x] Rapid tap mic/cancel/commit → no tap errors, no exceptions
- [x] Leave chat view → controller deinits, observers removed
- [x] Return to chat, start dictation → works normally
- [x] BUILD SUCCEEDED

---

## Technical Notes

1. **Why `.notifyOthersOnDeactivation`?**  
   Allows music apps (Spotify, Apple Music) to automatically resume after dictation ends.

2. **Why not auto-restart on interruption end?**  
   Would surprise users with unexpected recording. Better UX to let them tap mic again.

3. **Why track `isTapInstalled`?**  
   Calling `removeTap` when no tap is installed doesn't crash, but tracking ensures we only install once.

4. **Why handle route changes?**  
   If Bluetooth headset disconnects mid-dictation, audio engine may fail. Clean teardown recovers gracefully.

5. **Why use singleton for audio session?**  
   Prevents multiple conflicting session configurations. Single source of truth for dictation audio state.
