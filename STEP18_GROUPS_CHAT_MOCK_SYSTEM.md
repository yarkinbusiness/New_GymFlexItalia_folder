# Step 18: Groups/Chat Mock-First System with Private Invite Links - Summary

## Overview
Replaced the old backend-dependent Groups/Chat system with a mock-first, offline system and added private-group invite link sharing.

---

## PART A — Removed Legacy Groups Stack

### Verification
**GroupsService.shared usage in Views/ViewModels:** ❌ None (only in comments)
**RealtimeService.shared usage in Groups UI/VMs:** ❌ None

The following files no longer import or reference legacy services:
- `ViewModels/GroupsViewModel.swift` - Uses DI via `service` parameter
- `ViewModels/GroupChatViewModel.swift` - Uses DI via `service` parameter
- `Views/Groups/GroupsView.swift` - Uses `appContainer.groupsChatService`
- `Views/Groups/CreateGroupView.swift` - Uses `appContainer.groupsChatService`
- `Views/Groups/GroupChatView.swift` - Uses `appContainer.groupsChatService`

**Note:** Legacy `Services/GroupsService.swift` and `Services/RealtimeService.swift` remain in the codebase but are not used by Groups UI. They can be deleted if nothing else depends on them.

---

## PART B — Mock-First Groups Store + Service

### Files Created

| File | Description |
|------|-------------|
| `Core/Mock/MockGroupsStore.swift` | Singleton store with persistence |
| `Core/Services/GroupsChatServiceProtocol.swift` | Protocol for groups/chat operations |
| `Core/Services/Mock/MockGroupsChatService.swift` | Mock implementation |

### MockGroupsStore Features
```swift
MockGroupsStore.shared
├── @Published var groups: [FitnessGroup]
├── @Published var messagesByGroupId: [String: [Message]]
├── seedIfNeeded() - Seeds 6 groups with 10-25 messages each
├── createGroup(_:)
├── sendMessage(_:)
├── joinGroup(groupId:userId:)
├── leaveGroup(groupId:userId:)
└── Persists to UserDefaults: "groups_store_v1", "groups_messages_store_v1"
```

### Seed Data
- **6 Groups seeded** (mix of public/private):
  1. Rome Early Birds 🌅 (Public, Cardio)
  2. Strength Squad 💪 (Public, Strength)
  3. Yoga Flow Italia 🧘 (Public, Yoga)
  4. Private Workout Partners (Private, General)
  5. CrossFit Roma Elite (Private, CrossFit)
  6. Runners of Rome 🏃 (Public, Running)

- **10-25 messages per group** with realistic content

### MockGroupsChatService
- **Fetch delay:** 200-500ms
- **Send delay:** 150-300ms
- **Deterministic failure:** Message containing "FAIL" throws error

### AppContainer Integration
```swift
let groupsChatService: GroupsChatServiceProtocol

demo(): MockGroupsChatService()
live(): MockGroupsChatService() // Uses mock for offline operation
```

---

## PART C — Private Group Invite Link + Share Button

### FitnessGroup Model Updates
```swift
// Computed properties added to FitnessGroup
var isPrivate: Bool {
    !isPublic
}

var inviteLink: URL {
    URL(string: "gymflex://invite?groupId=\(id)")!
}

var shareText: String {
    "Join my GymFlex group '\(name)': gymflex://invite?groupId=\(id)"
}
```

### Invite Link Format
```
gymflex://invite?groupId=<group_id>
```

Example: `gymflex://invite?groupId=group_004`

### Share Button Location
The Share button appears in **two places** for private groups:

1. **Toolbar** - Top-right navigation bar button
   - Icon: `square.and.arrow.up`
   - Only visible when `group.isPrivate == true`

2. **Group Header** - Inside chat view header
   - Text: "Share Invite Link"
   - Only visible when `group.isPrivate == true`

**Public groups do NOT show Share button.**

### ShareSheet Implementation
Created `Views/Shared/ShareSheet.swift`:
```swift
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    // Wraps UIActivityViewController
}
```

---

## PART D — UI/VMs Wired to New DI Service

### GroupsViewModel
```swift
func load(using service: GroupsChatServiceProtocol) async
func loadAllGroups(using service: GroupsChatServiceProtocol) async
func loadMyGroups(using service: GroupsChatServiceProtocol) async
func createGroup(..., using service: GroupsChatServiceProtocol) async -> FitnessGroup?
func joinGroup(_:, using service: GroupsChatServiceProtocol) async
func leaveGroup(_:, using service: GroupsChatServiceProtocol) async
```

### GroupChatViewModel
```swift
func loadGroup(groupId:, using service: GroupsChatServiceProtocol) async
func refreshMessages(using service: GroupsChatServiceProtocol) async
func sendMessage(using service: GroupsChatServiceProtocol) async

// Current user identification
private let currentUserId = MockDataStore.mockUserId
private let currentUserName = "You"
```

### View Usage
```swift
// GroupsView
@Environment(\.appContainer) var appContainer

.task {
    await viewModel.load(using: appContainer.groupsChatService)
}

// GroupChatView
.task {
    await viewModel.loadGroup(groupId: groupId, using: appContainer.groupsChatService)
}
```

### Navigation
```swift
// RootTabView
case .groupDetail(let groupId):
    GroupChatView(groupId: groupId)  // Was: GroupDetailPlaceholderView
```

---

## Files Created/Modified

### Created
| File | Description |
|------|-------------|
| `Core/Mock/MockGroupsStore.swift` | Singleton store with persistence |
| `Core/Services/GroupsChatServiceProtocol.swift` | Service protocol |
| `Core/Services/Mock/MockGroupsChatService.swift` | Mock implementation |
| `Views/Shared/ShareSheet.swift` | UIActivityViewController wrapper |
| `Views/Groups/GroupChatView.swift` | Full chat view with share |

### Modified
| File | Changes |
|------|---------|
| `Core/AppContainer.swift` | Added `groupsChatService` |
| `Models/Group.swift` | Added `isPrivate`, `inviteLink`, `shareText` |
| `ViewModels/GroupsViewModel.swift` | Refactored to use DI |
| `ViewModels/GroupChatViewModel.swift` | Refactored, removed realtime |
| `Views/Groups/GroupsView.swift` | Uses DI, fixed empty state |
| `Views/Groups/CreateGroupView.swift` | Uses DI, better UI |
| `Views/Root/RootTabView.swift` | Uses GroupChatView |

---

## Definition of Done Tests

### ✅ Groups tab loads seeded groups offline
- No network/backend required
- 6 groups seeded on first launch

### ✅ Create Private group -> appears immediately
- Toggle between Public/Private in create modal
- Uses `appContainer.groupsChatService.createGroup()`
- New group added to `MockGroupsStore` and persisted

### ✅ Open private group -> Share button visible
- Toolbar button with `square.and.arrow.up` icon
- Header button "Share Invite Link"
- Both only visible for private groups

### ✅ Share opens native iOS share sheet with invite link
- Format: `gymflex://invite?groupId=<id>`
- Includes share text fallback

### ✅ Public groups do NOT show Share button
- `group.isPrivate == false` -> no share UI

### ✅ Sending message works; "FAIL" shows error
- Messages persist to `MockGroupsStore`
- "FAIL" in message text triggers deterministic error

### ✅ BUILD SUCCEEDED

---

## Legacy Code Status

The following legacy files are **no longer used** by Groups UI/VMs:
- `Services/GroupsService.swift` - Backend-dependent, uses AuthService
- `Services/RealtimeService.swift` - Socket-based realtime

These can be deleted if nothing else depends on them.
