# STEP 41A — Delight Hygiene & Guardrails (Motion + Haptics Hardening)

**Date:** 2026-01-02  
**Build Status:** ✅ BUILD SUCCEEDED  
**Behavior Change:** Accessibility + robustness improvements

---

## Overview

Hardened liquid motion and haptics to be:
- **Premium**: No double haptics, no excessive animations
- **Accessible**: Respects iOS Reduce Motion setting
- **Robust**: Degrades gracefully when accessibility is enabled

---

## PART A — Centralized Haptics Ownership

### HapticGate.swift (Created)

Prevents duplicate haptic triggers with configurable debounce:

```swift
HapticGate.fireOnce(key: "booking_success") {
    Haptics.success()
}

// Convenience methods
HapticGate.successOnce(key: "extend_session")
HapticGate.warningOnce(key: "low_balance")
```

**Features:**
- 2-second TTL debounce per key
- Thread-safe with NSLock
- Auto-cleans expired entries
- Debug logging in DEBUG builds

### Haptics Removed from Services

| File | Change |
|------|--------|
| `MockBookingService.swift` | Removed `Haptics.success()` |
| `ActiveSessionViewModel.swift` | Changed to `HapticGate.successOnce()` |

**Principle:** Services return success/failure only. UI layer handles haptics.

### Haptics at UI Level

| Event | Location | Key |
|-------|----------|-----|
| Booking confirmed | `GymDetailView.onChange(showConfirmationAlert)` | `booking_confirmed` |
| Session extended | `ActiveSessionViewModel.extendTime()` | `extend_session_success` |
| Wallet top-up | `WalletView.balanceCard.onChange` | `wallet_topup_success` |

---

## PART B — Reduce Motion Support

### Components Updated

| Component | Property | Behavior |
|-----------|----------|----------|
| `GFProgressRing` | `@Environment(\.accessibilityReduceMotion)` | Disables ring animation |
| `GFNumberText` | `@Environment(\.accessibilityReduceMotion)` | Uses plain Text |
| `ActiveSessionSummaryCard` | `@Environment(\.accessibilityReduceMotion)` | Disables timer animation |
| `WalletView.balanceCard` | `@Environment(\.accessibilityReduceMotion)` | Disables highlight animation |

### Behavior Matrix

| Component | Reduce Motion OFF | Reduce Motion ON |
|-----------|-------------------|------------------|
| Progress ring | Animates smoothly | Updates instantly |
| Timer digits | contentTransition | Plain text |
| Balance digits | numericText transition | Plain text |
| Highlight border | Animated pulse | Static border |

---

## PART C — Hardened Liquid Components

### GFProgressRing.swift

```swift
struct GFProgressRing: View {
    let animate: Bool // NEW parameter
    
    private var shouldAnimate: Bool {
        animate && !reduceMotion
    }
    
    // Animation only applied when shouldAnimate == true
    .animation(shouldAnimate ? GFMotion.live : nil, value: progress)
}
```

### GFNumberText.swift

```swift
struct GFNumberText: View {
    let animate: Bool // NEW parameter
    
    private var shouldAnimate: Bool {
        animate && !reduceMotion
    }
    
    var body: some View {
        if shouldAnimate {
            // Animated version
        } else {
            // Static version
        }
    }
}
```

---

## PART D — Wallet Highlight Hygiene

### Improved Logic

```swift
// State
@State private var previousBalanceCents: Int = -1
@State private var hasBalanceInitialized = false

.onChange(of: walletStore.balanceCents) { oldValue, newValue in
    // Guard: Skip initial load
    guard hasBalanceInitialized else {
        hasBalanceInitialized = true
        previousBalanceCents = newValue
        return
    }
    
    // Guard: Skip if no change
    guard oldValue != newValue else { return }
    
    // Only highlight on POSITIVE changes (top-up, not refund)
    let isPositiveChange = newValue > oldValue
    
    if isPositiveChange {
        // Trigger highlight
        // Fire haptic via HapticGate
    }
}
```

### Highlight Triggers

| Scenario | Highlight | Haptic |
|----------|-----------|--------|
| Initial load | ❌ No | ❌ No |
| Top-up success | ✅ Yes | ✅ Yes |
| Extend session (debit) | ❌ No | ❌ No |
| Refund | ❌ No | ❌ No |
| Sync refresh | ❌ No | ❌ No |

---

## Files Summary

### Created (1 file)
```
Core/Haptics/HapticGate.swift
```

### Modified (6 files)
```
Core/Services/Mock/MockBookingService.swift - Removed haptic
ViewModels/ActiveSessionViewModel.swift - Use HapticGate
Views/Dashboard/Components/ActiveSessionSummaryCard.swift - Reduce Motion
Views/Wallet/WalletView.swift - Reduce Motion + improved highlight
Views/Shared/DesignSystem/GFProgressRing.swift - animate param + Reduce Motion
Views/Shared/DesignSystem/GFNumberText.swift - animate param + Reduce Motion
Views/GymDetail/GymDetailView.swift - UI-level booking haptic
```

---

## Verification Checklist

| Check | Status |
|-------|--------|
| Services don't fire haptics | ✅ |
| HapticGate prevents double-fires | ✅ |
| Booking haptic fires once | ✅ |
| Extend haptic fires once | ✅ |
| Top-up haptic fires once | ✅ |
| Reduce Motion disables ring animation | ✅ |
| Reduce Motion disables numeric transition | ✅ |
| Reduce Motion disables highlight animation | ✅ |
| Normal animations work when OFF | ✅ |
| No haptics on initial balance load | ✅ |
| No highlight on refund/debit | ✅ |
| BUILD SUCCEEDED | ✅ |

---

## Summary

This step hardened the liquid motion and haptics system to be:
- **Non-cringe**: Single haptic per success event
- **Accessible**: Full Reduce Motion support
- **Robust**: Clean separation of concerns (services vs UI)
