# Step 25: Help & Support Feature - Summary

## Overview
Implemented a mock-first Help & Support feature with FAQ, contact support via email, bug reporting with diagnostics, legal placeholders, and app info display.

---

## PART A — App Diagnostics Helper

### Core/Diagnostics/AppDiagnostics.swift (NEW)

**Static Methods:**
```swift
appVersionString() -> String     // "1.0.0"
buildNumberString() -> String    // "42"
fullVersionString() -> String    // "1.0.0 (42)"
environmentString() -> String    // "Demo"
iosVersionString() -> String     // "18.0"
deviceModelString() -> String    // "iPhone 16 Pro" or "Simulator"
deviceInfoString() -> String     // "iOS 18.0 • iPhone 16 Pro"
localeString() -> String         // "en_US"
timezoneString() -> String       // "Europe/Rome"
diagnosticsSummary() -> String   // Full multi-line diagnostics
shortDiagnostics() -> String     // "v1.0.0 • Demo • iOS 18.0"
```

**diagnosticsSummary() Output:**
```
--- App Diagnostics ---
App Version: 1.0.0 (42)
Environment: Demo
Device: iPhone 16 Pro
iOS Version: 18.0
Locale: en_US
Timezone: Europe/Rome
Date: 2026-01-02T02:30:00+03:00
-----------------------
```

---

## PART B — FAQ

### Core/Support/FAQItem.swift (NEW)
```swift
struct FAQItem: Identifiable, Hashable {
    let id: String
    let question: String
    let answer: String
}
```

### Core/Support/FAQStore.swift (NEW)
- Singleton with 12 hardcoded FAQ items
- Version tracking for future updates
- Topics covered:
  - Booking sessions
  - Wallet top-ups
  - Cancellations
  - Check-in
  - Session extension
  - Groups
  - Payment methods
  - Refunds
  - Finding gyms
  - Notifications
  - Profile updates
  - Security (Face ID/Touch ID)

### Views/Profile/Support/FAQView.swift (NEW)
- List of expandable FAQ rows
- Tap to expand/collapse answers
- Smooth animation
- Single item expanded at a time

---

## PART C — Help & Support Hub

### Views/Profile/Support/HelpSupportView.swift (NEW)

**Sections:**

1. **Help**
   - FAQ → `.faq` route

2. **Contact**
   - Contact Support → Opens mail composer with diagnostics
   - Report a Bug → `.reportBug` route

3. **Legal**
   - Terms of Service → `.terms` route
   - Privacy Policy → `.privacy` route

4. **App Info**
   - Version
   - Build
   - Environment
   - Copyright footer

**Mail Handling:**
- Uses `MFMailComposeViewController` when available
- Falls back to `mailto:` URL
- Shows alert if neither works: "Mail is not configured on this device."

---

## PART D — Report Bug Screen

### Views/Profile/Support/ReportBugView.swift (NEW)

**UI:**
- Bug icon
- Explanation text
- 3-step instruction list
- **Copy Diagnostics** button → Copies to clipboard, shows toast
- **Email Support** button → Opens mail with bug report template

**DEBUG Section:**
- Shows diagnostics preview (only in DEBUG builds)

---

## PART E — Legal Placeholders

### Views/Profile/Support/LegalPlaceholderViews.swift (NEW)

- `TermsPlaceholderView`
- `PrivacyPlaceholderView`
- Both show "Coming Soon" message
- Contact info for legal inquiries

---

## PART F — Navigation Wiring

### AppRoute (AppRouter.swift)
Added:
```swift
case helpSupport
case faq
case reportBug
case terms
case privacy
```

### Router Helper Methods
```swift
func pushHelpSupport()
func pushFAQ()
func pushReportBug()
func pushTerms()
func pushPrivacy()
```

### RootTabView Navigation
Added destinations for all 5 new routes.

### ProfileView (MODIFIED)
Added "Help & Support" row with questionmark.circle icon.

---

## Files Created

| File | Description |
|------|-------------|
| `Core/Diagnostics/AppDiagnostics.swift` | Diagnostic info helpers |
| `Core/Support/FAQItem.swift` | FAQ item model |
| `Core/Support/FAQStore.swift` | FAQ data store |
| `Views/Profile/Support/FAQView.swift` | Expandable FAQ list |
| `Views/Profile/Support/HelpSupportView.swift` | Help hub with mail composer |
| `Views/Profile/Support/ReportBugView.swift` | Bug report with copy/email |
| `Views/Profile/Support/LegalPlaceholderViews.swift` | Terms & Privacy placeholders |

## Files Modified

| File | Changes |
|------|---------|
| `Core/Navigation/AppRouter.swift` | Added 5 routes + 5 helper methods |
| `Views/Root/RootTabView.swift` | Added 5 navigation destinations |
| `Views/Profile/ProfileView.swift` | Added Help & Support row |

---

## Key Behaviors

| Feature | Status |
|---------|--------|
| **FAQ expand/collapse** | ✅ Tapping rows toggles answer visibility |
| **Mail composer** | ✅ Opens with diagnostics prefilled |
| **Mail fallback** | ✅ Uses mailto: URL if composer unavailable |
| **Mail unavailable alert** | ✅ Shows alert with alternative email |
| **Copy diagnostics** | ✅ Copies to clipboard, shows toast |
| **App info display** | ✅ Shows version, build, environment |

---

## Definition of Done Tests

### ✅ Profile → Help & Support opens
- Tap row in Profile → HelpSupportView displays

### ✅ FAQ expands/collapses
- Tap question → Answer appears
- Tap again → Answer hides
- Tap different question → Previous collapses, new expands

### ✅ Contact Support opens mail with diagnostics prefilled
- Subject: "GymFlex Support"
- Body includes greeting + diagnosticsSummary()

### ✅ Report Bug copies diagnostics to clipboard
- Tap "Copy Diagnostics"
- Toast "Diagnostics copied!" appears
- Paste in Notes/Mail to verify

### ✅ App Info shows correct version/build
- Version matches CFBundleShortVersionString
- Build matches CFBundleVersion
- Environment shows "Demo"

---

## Build Status: ✅ **BUILD SUCCEEDED**
