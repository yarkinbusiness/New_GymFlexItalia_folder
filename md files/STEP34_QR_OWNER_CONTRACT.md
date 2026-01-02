# STEP 34 — Owner App Contract: QR Validation & Session Usage

**Date:** 2026-01-02  
**Build Status:** ✅ BUILD SUCCEEDED  
**Behavior Change:** None (existing user app unchanged)

---

## Overview

Defined clean, future-proof contracts for:
1. How gym owners validate user QR codes
2. How session usage/spending is tracked

All logic is mock-based and deterministic. No backend required yet.

---

## PART A — QR Payload Contract

### File Created
`Core/QR/QRPayload.swift`

### Structure
```swift
struct QRPayload: Codable {
    let bookingId: String
    let gymId: String
    let userId: String
    let sessionStart: Date
    let sessionEnd: Date
    let referenceCode: String
    let checksum: String  // SHA256 of all other fields
}
```

### Features
| Feature | Description |
|---------|-------------|
| `generate(from:)` | Create from Booking model |
| `toQRString()` | Encode as JSON for QR code |
| `from(qrString:)` | Decode from scanned QR |
| `isChecksumValid` | Verify integrity |
| `isWithinSessionWindow` | Check timing |
| `remainingMinutes` | Time left in session |

### Security
- **SHA256 checksum** prevents tampering
- Checksum covers all fields
- First 16 hex chars used (compact)
- DEBUG assertion on mismatch

---

## PART B — Validation Result Contract

### File Created
`Core/QR/QRValidationResult.swift`

### Status Enum
```swift
enum QRValidationStatus {
    case valid           // ✅ Allow check-in
    case expired         // ⏰ Session ended
    case invalid         // ❌ Bad format/checksum
    case wrongGym        // 🏢 Different gym
    case notStarted      // ⏳ Session hasn't started
    case alreadyCheckedIn // ℹ️ User already in gym
    case cancelled       // 🚫 Booking cancelled
}
```

### Result Structure
```swift
struct QRValidationResult {
    let status: QRValidationStatus
    let bookingId: String?
    let gymId: String?
    let userId: String?
    let referenceCode: String?
    let remainingMinutes: Int?
    let message: String  // Human-readable
    let sessionStart: Date?
    let sessionEnd: Date?
}
```

### Factory Methods
- `.valid(payload:, remainingMinutes:)`
- `.expired(payload:)`
- `.notStarted(payload:)`
- `.wrongGym(payload:, expectedGymId:)`
- `.invalid(reason:)`
- `.alreadyCheckedIn(payload:)`
- `.cancelled(payload:)`

---

## PART C — Session Usage Report

### File Created
`Core/Owner/SessionUsageReport.swift`

### Structure
```swift
struct SessionUsageReport {
    // Booking Reference
    let bookingId: String
    let gymId: String
    let userId: String
    let referenceCode: String
    
    // Timing
    let bookingStartTime: Date
    let bookingEndTime: Date
    let checkInTime: Date
    let checkOutTime: Date?
    
    // Usage
    let totalMinutesUsed: Int
    let bookedMinutes: Int
    let extensionMinutes: Int
    
    // Billing
    let totalAmountCharged: Int  // cents
    let currency: String
    let hourlyRateCents: Int
    let paymentCompleted: Bool
    
    // Status
    let status: SessionStatus
    let endReason: EndReason?
}
```

### Billing Rules
- Per-minute billing
- Minimum charge: 15 minutes
- Extensions added to usage
- Gym rate looked up from MockDataStore

---

## PART D — Mock Validation Service

### File Created
`Core/Services/Owner/MockQRValidationService.swift`

### Protocol
```swift
protocol QRValidationServiceProtocol {
    func validate(qrString:, validatorGymId:) async -> QRValidationResult
    func validate(payload:, validatorGymId:) async -> QRValidationResult
}
```

### Validation Pipeline
```
1. Decode QR string → QRPayload
2. Verify checksum (SHA256)
3. Check gymId matches validator's gym
4. Check booking status (not cancelled)
5. Verify session timing
    - Not expired
    - Not too early
6. Return QRValidationResult
```

### Debug Helpers
```swift
#if DEBUG
createTestValidPayload(gymId:)
createTestExpiredPayload(gymId:)
createTestWrongGymPayload(wrongGymId:)
#endif
```

---

## PART E — QRService Integration

### File Modified
`Services/QRService.swift`

### New Methods
```swift
// Generate QR code from payload
func generateQRCode(from payload: QRPayload, size:) -> UIImage?

// Generate payload from booking
func generatePayload(from booking: Booking) -> QRPayload

// Generate QR code using new format
func generateBookingQRCodeV2(booking:, size:) -> UIImage?
```

### Backward Compatibility
- Existing `generateBookingQRCode` unchanged
- New `generateBookingQRCodeV2` uses QRPayload format
- Owner app can validate both formats

---

## PART F — Guardrails

### DEBUG Assertions
| Location | Assertion |
|----------|-----------|
| `QRPayload.isChecksumValid` | Logs mismatch |
| `MockQRValidationService.validate` | assertionFailure on tampered checksum |

### Documentation
- All structures have comprehensive doc comments
- Contract purpose clearly stated
- Usage examples in comments

---

## Files Summary

### Created (4 files)
```
Core/QR/QRPayload.swift
Core/QR/QRValidationResult.swift
Core/Owner/SessionUsageReport.swift
Core/Services/Owner/MockQRValidationService.swift
```

### Modified (1 file)
```
Services/QRService.swift (added QRPayload integration)
```

---

## Data Flow Diagram

```
┌────────────────────────────────────────────────────────────┐
│                      USER APP                               │
├────────────────────────────────────────────────────────────┤
│                                                             │
│   Booking                                                   │
│      │                                                      │
│      ▼                                                      │
│   QRPayload.generate(from: booking)                        │
│      │                                                      │
│      ▼                                                      │
│   QRPayload                                                 │
│   ┌─────────────────────────────────────┐                  │
│   │ bookingId: "bk_123"                 │                  │
│   │ gymId: "gym_1"                      │                  │
│   │ userId: "user_001"                  │                  │
│   │ sessionStart: 2026-01-02T10:00:00   │                  │
│   │ sessionEnd: 2026-01-02T11:00:00     │                  │
│   │ referenceCode: "CHK-ABC123"         │                  │
│   │ checksum: "a1b2c3d4e5f67890"        │                  │
│   └─────────────────────────────────────┘                  │
│      │                                                      │
│      ▼                                                      │
│   QRPayload.toQRString() → JSON                            │
│      │                                                      │
│      ▼                                                      │
│   QRService.generateQRCode(from:) → UIImage                │
│      │                                                      │
│      ▼                                                      │
│   Display QR on Check-in Tab                               │
│                                                             │
└────────────────────────────────────────────────────────────┘
                           │
                    (Owner scans QR)
                           │
                           ▼
┌────────────────────────────────────────────────────────────┐
│                     OWNER APP                               │
├────────────────────────────────────────────────────────────┤
│                                                             │
│   Scanned QR String                                         │
│      │                                                      │
│      ▼                                                      │
│   MockQRValidationService.validate(qrString:, validatorGymId:)
│      │                                                      │
│      ├── Decode → QRPayload                                │
│      ├── Verify checksum                                    │
│      ├── Check gym ID                                       │
│      ├── Check booking status                               │
│      ├── Check timing                                       │
│      │                                                      │
│      ▼                                                      │
│   QRValidationResult                                        │
│   ┌─────────────────────────────────────┐                  │
│   │ status: .valid                      │                  │
│   │ remainingMinutes: 55                │                  │
│   │ message: "✅ Valid. 55min left."    │                  │
│   └─────────────────────────────────────┘                  │
│      │                                                      │
│      ▼                                                      │
│   Display result to gym owner                              │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## Verification Checklist

| Test | Expected | Status |
|------|----------|--------|
| Book a gym | Creates booking | ✅ |
| Open Check-in tab | Shows QR code | ✅ |
| QR renders correctly | UIImage displayed | ✅ |
| No crashes | App stable | ✅ |
| Existing behavior unchanged | All flows work | ✅ |
| BUILD SUCCEEDED | ✅ | ✅ |

---

## Next Steps (Future)

1. **Camera Integration** — Add QR scanner to owner app
2. **Backend API** — Replace MockQRValidationService with live calls
3. **Session Tracking** — Real-time usage reporting
4. **Billing Integration** — Connect to payment provider
5. **Owner Dashboard** — Display SessionUsageReports
