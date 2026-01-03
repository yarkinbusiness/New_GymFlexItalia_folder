# FEATURE — Tap Gym Pin on Discover Map to Start Route

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Feature Summary

When user taps a gym pin on the Discover tab map, a bottom sheet appears with:
- Gym name, address, and price
- **Route** button → Opens Apple Maps with driving directions
- **View Details** button → Navigates to GymDetailView

---

## Files Modified (1)

| File | Changes |
|------|---------|
| `Views/Discovery/GymDiscoveryView.swift` | Added `selectedGymForSheet` state, `GymPinActionSheet` component, `openAppleMapsRoute()` function |

---

## Implementation Details

### Part 1: Gym Model ✅
Gym model already has `latitude` and `longitude` properties with a computed `coordinate: CLLocationCoordinate2D`.

### Part 2: Map Pin Tap Handling
Updated `mapView` section to set `selectedGymForSheet` instead of immediately navigating:

```swift
onGymSelected: { gym in
    viewModel.selectGym(gym)
    selectedGymForSheet = gym  // Show sheet instead of navigate
}
```

### Part 3: Bottom Sheet with Route/Details

```swift
.sheet(item: $selectedGymForSheet) { gym in
    GymPinActionSheet(
        gym: gym,
        onRoute: { openAppleMapsRoute(to: gym) },
        onViewDetails: { router.pushGymDetail(gymId: gym.id) },
        onDismiss: { selectedGymForSheet = nil }
    )
    .presentationDetents([.height(220)])
    .presentationDragIndicator(.visible)
}
```

### Part 4: Apple Maps Integration

```swift
private func openAppleMapsRoute(to gym: Gym) {
    let coordinate = gym.coordinate
    
    guard CLLocationCoordinate2DIsValid(coordinate) else {
        print("⚠️ Invalid coordinates for gym: \(gym.name)")
        return
    }
    
    let placemark = MKPlacemark(coordinate: coordinate)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = gym.name
    
    let launchOptions: [String: Any] = [
        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
    ]
    
    mapItem.openInMaps(launchOptions: launchOptions)
}
```

### Part 5: Missing Data Handling

The `GymPinActionSheet` checks for valid coordinates:

```swift
private var hasValidCoordinates: Bool {
    CLLocationCoordinate2DIsValid(gym.coordinate) &&
    gym.latitude != 0 && gym.longitude != 0
}
```

- If coordinates invalid: Route button is disabled + shows warning message
- View Details button always works

---

## GymPinActionSheet Component

```
┌─────────────────────────────────────────┐
│ Gym Name                           [X]  │
│ Address                                 │
│ €XX.X/hour                              │
├─────────────────────────────────────────┤
│  [🧭 Route]         [ℹ️ Details]        │
│                                         │
│ ⚠️ Location unavailable (if invalid)   │
└─────────────────────────────────────────┘
```

---

## User Flow

1. Open Discover tab
2. Switch to Map view
3. Tap gym pin on map
4. Bottom sheet appears with gym info
5. **Tap "Route"**: Apple Maps opens with driving directions to gym
6. **Tap "Details"**: App navigates to GymDetailView
7. **Tap X or swipe down**: Sheet closes

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Gym has valid coordinates | Route button enabled, works normally |
| Gym has `latitude: 0, longitude: 0` | Route button disabled, warning shown |
| Gym has invalid coordinates | Route button disabled, warning shown |
| User taps gym in list view | Still navigates directly to GymDetailView (unchanged) |

---

## Verification Checklist

| Test | Expected | Status |
|------|----------|--------|
| Tap gym pin on map | Sheet appears | ✅ |
| Sheet shows gym name | ✅ | ✅ |
| Sheet shows address | ✅ | ✅ |
| Sheet shows price | ✅ | ✅ |
| Tap "Route" | Apple Maps opens with directions | ✅ |
| Tap "Details" | App opens GymDetailView | ✅ |
| Tap X | Sheet closes | ✅ |
| Invalid coordinates | Route disabled + warning | ✅ |
| List view tap | Still works (direct navigation) | ✅ |
| BUILD SUCCEEDED | ✅ | ✅ |

---

## Dependencies

- `MapKit` (already imported)
- `MKMapItem.openInMaps()` - Opens Apple Maps app

---

## Notes

- Uses `MKLaunchOptionsDirectionsModeDriving` for driving directions
- Could be extended to support `.walking` or `.transit` modes
- Gym detail navigation from list view unchanged (still direct)
