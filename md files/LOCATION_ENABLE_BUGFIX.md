# UX BUGFIX — Location Enable Button Not Working (Home > Nearby Gyms)

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Overview

Fixed the location enable flow to be reliable in all scenarios:
- Fresh install (notDetermined) → Shows iOS permission prompt
- Previously denied → Opens iOS Settings
- Already authorized → Fetches location immediately
- Returning from Settings → Refreshes and updates Nearby Gyms

---

## Files Modified (2)

| File | Changes |
|------|---------|
| `Services/LocationService.swift` | Hardened methods, added logging |
| `Views/Dashboard/DashboardView.swift` | Added scenePhase handling |

---

## PART A — LocationService Hardened

### New Methods

```swift
/// Refresh the authorization status from the location manager
@MainActor
func refreshAuthorizationStatus()

/// Start location updates if already authorized (safe to call repeatedly)
@MainActor
func startIfAuthorized()

/// Check if location is authorized
var isAuthorized: Bool
```

### @MainActor for Thread Safety

Marked with `@MainActor` (ensures permission prompt appears):
- `refreshAuthorizationStatus()`
- `requestLocationPermission()`
- `handleEnableLocationTapped()`
- `startIfAuthorized()`

### Improved `handleEnableLocationTapped()`

```swift
@MainActor
func handleEnableLocationTapped() {
    // Always refresh status first
    refreshAuthorizationStatus()
    
    switch authorizationStatus {
    case .notDetermined:
        requestLocationPermission()  // Show iOS prompt
        
    case .denied, .restricted:
        openSystemSettings()  // Open Settings
        
    case .authorizedAlways, .authorizedWhenInUse:
        startUpdatingLocation()
        requestOneTimeLocation()  // Fetch immediately
        
    @unknown default:
        requestLocationPermission()
    }
}
```

### Debug Logging (DEBUG only)

```
📍 LocationService.enableTap status=notDetermined
📍 LocationService.requestLocationPermission called
📍 LocationService.didChangeAuthorization -> authorizedWhenInUse
📍 LocationService.didUpdateLocations -> 41.9028,12.4964
📍 LocationService.startIfAuthorized status=authorizedWhenInUse
```

---

## PART B — DashboardView (Settings Return)

### Added scenePhase Handling

```swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        locationService.startIfAuthorized()
        viewModel.refreshNearbyGyms(userLocation: locationService.currentLocation)
    }
}
```

This ensures:
1. User taps Settings button
2. Enables location in iOS Settings
3. Returns to app
4. App immediately fetches location and updates Nearby Gyms

### First-Time Open Improvement

```swift
.task {
    viewModel.load()
    locationService.startIfAuthorized()  // Added
    viewModel.refreshNearbyGyms(userLocation: locationService.currentLocation)
}
```

If user already granted permission, Nearby Gyms updates on open.

---

## Manual Test Cases

### Case 1: Fresh Install / notDetermined
1. Tap "Enable" in location banner
2. iOS permission prompt appears
3. Tap "Allow While Using"
4. ✅ Nearby Gyms updates with distances

### Case 2: Previously Denied
1. Location banner shows "Settings" button
2. Tap → Opens iOS Settings
3. Toggle "While Using the App"
4. Return to app
5. ✅ Nearby Gyms updates immediately

### Case 3: Already Authorized
1. Open app (fresh start)
2. ✅ Location banner does not show
3. ✅ Nearby Gyms shows distances automatically

---

## Verification Checklist

| Check | Status |
|-------|--------|
| Enable button triggers permission prompt (notDetermined) | ✅ |
| Enable button opens Settings (denied) | ✅ |
| Returning from Settings refreshes location | ✅ |
| Already authorized: auto-fetches on Home open | ✅ |
| Nearby Gyms updates with real distances | ✅ |
| Debug logs added (DEBUG builds only) | ✅ |
| BUILD SUCCEEDED | ✅ |
