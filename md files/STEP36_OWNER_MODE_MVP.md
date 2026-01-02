# STEP 36 — Owner Mode MVP (QR Validation)

**Date:** 2026-01-02  
**Build Status:** ✅ BUILD SUCCEEDED  
**Behavior Change:** None (DEBUG-only feature)

---

## Overview

Added a DEBUG-only "Owner Mode" to validate user QR codes and preview session usage reports. This proves the Step 34 QR contract end-to-end without camera scanning.

---

## PART A — Routing (DEBUG-only)

### File Modified
`Core/Navigation/AppRouter.swift`

### Changes
```swift
// Added route case
case ownerMode  // DEBUG-only: QR validation for gym owners

// Added navigation helper (gated)
#if DEBUG
func pushOwnerMode() {
    appendRoute(.ownerMode)
}
#endif
```

### File Modified
`Views/Root/RootTabView.swift`

```swift
#if DEBUG
case .deepLinkSimulator:
    DeepLinkSimulatorView()
case .ownerMode:
    OwnerModeView()  // NEW
#endif
```

---

## PART B — Debug Entry Point

### File Modified
`Views/Settings/SettingsView.swift`

Added button in debug section:

```swift
// Open Owner Mode (QR Validator)
Button {
    DemoTapLogger.log("Debug.OpenOwnerMode")
    router.pushOwnerMode()
} label: {
    SettingsRow(
        icon: "qrcode.viewfinder",
        iconColor: .indigo,
        title: "Owner Mode (QR Validate)"
    )
}
```

This is inside the `#if DEBUG` block, ensuring no Release access.

---

## PART C — Owner Mode ViewModel

### File Created
`ViewModels/OwnerModeViewModel.swift`

Entirely wrapped in `#if DEBUG`.

### Published Properties
| Property | Type | Description |
|----------|------|-------------|
| `selectedGymId` | String | Gym owner's gym for validation |
| `qrInput` | String | Raw QR payload JSON |
| `isLoading` | Bool | Loading state |
| `validationResult` | QRValidationResult? | Result from service |
| `decodedPayload` | QRPayload? | Decoded for display |
| `reportPreview` | SessionUsageReport? | Generated report |
| `errorMessage` | String? | Error message |
| `successMessage` | String? | Success confirmation |

### Methods
| Method | Description |
|--------|-------------|
| `pasteFromClipboard()` | Paste QR content from clipboard |
| `clearInput()` | Clear QR input and results |
| `loadSamplePayload()` | Load from active booking or test |
| `validate()` | Validate through MockQRValidationService |
| `generateReportPreview()` | Create SessionUsageReport |
| `copyReportJSON()` | Copy report JSON to clipboard |

### Computed Properties
| Property | Description |
|----------|-------------|
| `allGyms` | All gyms from MockDataStore |
| `selectedGymName` | Name of selected gym |
| `hasValidationResult` | Whether result exists |
| `canGenerateReport` | Has valid bookingId |
| `statusColor` | Color for result badge |
| `statusIcon` | SF Symbol for result |

---

## PART D — Owner Mode UI

### File Created
`Views/Owner/OwnerModeView.swift`

Entirely wrapped in `#if DEBUG`.

### Sections
| Section | Description |
|---------|-------------|
| Header | Title + description |
| Gym Context | Picker to select validation gym |
| QR Input | TextEditor + Paste/Clear/Sample buttons |
| Validate | Primary action button |
| Messages | Error/success banners |
| Validation Result | Status badge + payload details |
| Usage Report | Generate + view + copy JSON |

### Features
- **Gym Picker**: Select which gym is doing the validation
- **QR Input**: Paste JSON payload manually
- **Load Sample**: Auto-generate test payload or use active booking
- **Validation**: Shows status (valid/invalid/expired/wrong gym)
- **Payload Details**: All decoded fields displayed
- **Usage Report**: Generate preview and copy JSON

---

## PART E — Validation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Owner Mode UI                            │
├─────────────────────────────────────────────────────────────┤
│  1. Select Gym (gym_1, gym_2, etc.)                         │
│  2. Paste QR payload JSON                                    │
│  3. Tap "Validate QR"                                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               MockQRValidationService                        │
├─────────────────────────────────────────────────────────────┤
│  1. Decode QR string → QRPayload                            │
│  2. Verify SHA256 checksum                                   │
│  3. Check gymId matches selectedGymId                        │
│  4. Check booking status (cancelled?)                        │
│  5. Check time window (not started? expired?)                │
│  6. Return QRValidationResult                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Display Result                             │
├─────────────────────────────────────────────────────────────┤
│  ✅ Valid: Green badge + remaining minutes                   │
│  ⏰ Expired: Orange badge + "Session has expired"           │
│  🏢 Wrong Gym: Red badge + "Different gym"                  │
│  ❌ Invalid: Red badge + "Checksum failed"                  │
└─────────────────────────────────────────────────────────────┘
```

---

## PART F — Test Scenarios

### Test 1: Valid QR
1. Book a gym session
2. Open Check-in tab (QR is generated)
3. Navigate: Settings → Owner Mode
4. Select matching gym in picker
5. Tap "Load Sample" or paste QR from Check-in
6. Tap "Validate QR"
7. **Expected**: Green "Valid" badge, remaining minutes shown

### Test 2: Wrong Gym
1. Same as above, but select different gym in picker
2. **Expected**: Red "Wrong Gym" badge

### Test 3: Invalid Checksum
1. Paste valid QR, then modify any character
2. **Expected**: Red "Invalid" badge + "Checksum failed"

### Test 4: Expired Session
1. Use test expired payload or wait for session to end
2. **Expected**: Orange "Expired" badge

### Test 5: Report Preview
1. Validate a valid QR
2. Tap "Generate Usage Report"
3. View summary + JSON
4. Tap "Copy JSON"
5. **Expected**: JSON copied to clipboard

---

## Files Summary

### Created (2 files)
```
ViewModels/OwnerModeViewModel.swift
Views/Owner/OwnerModeView.swift
```

### Modified (3 files)
```
Core/Navigation/AppRouter.swift
Views/Root/RootTabView.swift
Views/Settings/SettingsView.swift
```

---

## DEBUG-Only Verification

| Check | Status |
|-------|--------|
| `OwnerModeView` wrapped in `#if DEBUG` | ✅ |
| `OwnerModeViewModel` wrapped in `#if DEBUG` | ✅ |
| Route `.ownerMode` destination wrapped in `#if DEBUG` | ✅ |
| `pushOwnerMode()` wrapped in `#if DEBUG` | ✅ |
| Settings button in debug section (gated) | ✅ |
| No Release entry points | ✅ |
| BUILD SUCCEEDED | ✅ |

---

## Usage Example

```swift
// In DEBUG build, from SettingsView debug section:
router.pushOwnerMode()

// In OwnerModeView:
// 1. Select gym from picker
// 2. Paste QR or load sample
// 3. Tap Validate
// 4. View result
// 5. Generate usage report if valid
// 6. Copy JSON to clipboard
```
