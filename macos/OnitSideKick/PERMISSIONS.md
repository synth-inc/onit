# Permissions System

This document describes how Onit handles macOS permissions, including the permission flow, entry points, and implementation details.

## Overview

Onit requires several macOS permissions to function properly:

| Permission | Required For | Manager Class |
|------------|--------------|---------------|
| **Accessibility** | Context loading, text insertion, window resizing, AutoContext | `AccessibilityPermissionManager` |
| **Screen Recording** | Screenshots, QuickEdit feature | `ScreenRecordingPermissionManager` |
| **Microphone** | Voice transcription | `MicrophoneInputManager` |
| **Keyboard (Input Source)** | Searchback feature | `KeyboardPermissionManager` |

## Permission Managers

### AccessibilityPermissionManager

**File:** `Onit/Accessibility/Permission/AccessibilityPermissionManager.swift`

**Key Methods:**

| Method | Description |
|--------|-------------|
| `requestPermission()` | Shows native macOS dialog via `AXIsProcessTrustedWithOptions()` |
| `openAccessibilitySettingsWindow()` | Opens System Settings > Privacy & Security > Accessibility |

**Permission Check:**
- Uses `AXIsProcessTrusted()` to check current status
- Timer-based polling every 0.5 seconds to detect permission changes
- Published property: `@Published var accessibilityPermissionStatus: AccessibilityPermissionStatus`

**Native Dialog Trigger:**
```swift
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
AXIsProcessTrustedWithOptions(options)
```

---

### ScreenRecordingPermissionManager

**File:** `Onit/ScreenRecording/ScreenRecordingPermissionManager.swift`

**Key Methods:**

| Method | Description |
|--------|-------------|
| `requestScreenRecordingPermission()` | Shows native dialog, falls back to Settings if denied |
| `openScreenRecordingSettings()` | Opens System Settings > Privacy & Security > Screen Recording |
| `hasScreenRecordingPermission()` | Returns current permission status |

**Permission Check:**
- Uses `CGPreflightScreenCaptureAccess()` to check current status
- Published property: `@Published var isScreenRecordingEnabled: Bool`

**Native Dialog Trigger:**
```swift
_ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
```

**Flow:**
1. Attempts to trigger native dialog via ScreenCaptureKit API
2. If permission denied, automatically opens System Settings
3. Sets `Defaults[.screenRecordingPermissionAsked] = true` after first request

---

### MicrophoneInputManager

**File:** `Onit/Transcription/Services/MicrophoneInputManager.swift`

**Key Methods:**

| Method | Description |
|--------|-------------|
| `requestPermission()` | Shows native dialog, returns `Bool` |
| `requestPermissionOrOpenSettings()` | Shows native dialog if `notDetermined`, opens Settings if `denied` |
| `openMicrophoneSettings()` | Opens System Settings > Privacy & Security > Microphone |

**Permission Check:**
- Uses `AVCaptureDevice.authorizationStatus(for: .audio)` to check current status
- Timer-based polling every 0.5 seconds to detect permission changes
- Published property: `@Published var hasPermission: Bool`

**Native Dialog Trigger:**
```swift
await AVCaptureDevice.requestAccess(for: .audio)
```

**Permission States:**
- `.notDetermined` - User hasn't been asked yet, can show native dialog
- `.authorized` - Permission granted
- `.denied` - User denied, must open System Settings
- `.restricted` - System restriction, must open System Settings

---

### KeyboardPermissionManager

**File:** `Onit/Keyboard/KeyboardPermissionManager.swift`

**Key Methods:**

| Method | Description |
|--------|-------------|
| `openKeyboardSettings()` | Opens System Settings > Keyboard > Input Sources |

**Note:** Keyboard/Input Source doesn't use a native permission dialog. Users must manually add the Onit input source in System Settings.

---

## Entry Points

All permission entry points now use native dialogs when possible, with automatic fallback to System Settings when the permission has already been denied.

### Onboarding

| Screen | File | Permission | Method Called |
|--------|------|------------|---------------|
| Accessibility First Screen | `OnboardingAccessibility.swift` | Accessibility | `requestPermission()` |
| Permissions Page | `OnboardingPermissions.swift` | Accessibility | `requestPermission()` |
| Permissions Page | `OnboardingPermissions.swift` | Screen Recording | `requestScreenRecordingPermission()` |
| Permissions Page | `OnboardingPermissions.swift` | Microphone | `requestPermission()` |
| Permissions Page | `OnboardingPermissions.swift` | Keyboard | `openKeyboardSettings()` |

### Settings

| Page | File | Permission | Method Called |
|------|------|------------|---------------|
| Setup | `SettingsSetup.swift` | Accessibility | `requestPermission()` |
| Setup | `SettingsSetup.swift` | Screen Recording | `requestScreenRecordingPermission()` |
| Setup | `SettingsSetup.swift` | Microphone | `requestPermissionOrOpenSettings()` |
| Setup | `SettingsSetup.swift` | Keyboard | `openKeyboardSettings()` |
| Sidekick Context | `SettingsSidekickContext.swift` | Accessibility | `requestPermission()` |
| Sidekick Behavior | `SettingsSidekickBehavior.swift` | Accessibility | `requestPermission()` |

### Menu Bar

| Component | File | Permission | Method Called |
|-----------|------|------------|---------------|
| "Allow access..." item | `MenuBarCheckForPermissions.swift` | Accessibility | `requestPermission()` |
| "Allow access..." item | `MenuBarCheckForPermissions.swift` | Screen Recording | `requestScreenRecordingPermission()` |
| "Allow access..." item | `MenuBarCheckForPermissions.swift` | Microphone | `requestPermissionOrOpenSettings()` |
| Status message click | `AppState+Status.swift` | Accessibility | `requestPermission()` |
| Status message click | `AppState+Status.swift` | Screen Recording | `requestScreenRecordingPermission()` |
| Status message click | `AppState+Status.swift` | Microphone | `requestPermissionOrOpenSettings()` |

---

## Status System

### Menu Bar Status Dot

The menu bar icon displays a colored status dot indicating the app's permission state:

| Color | Meaning |
|-------|---------|
| **Red** | Critical permission missing (Accessibility, Screen Recording, Microphone, Keyboard not added) |
| **Orange** | Warning state (Keyboard not selected, app disabled) |
| **Gray** | All features disabled |
| **Green** | All permissions granted, app running normally |

### Status Priority

Permissions are checked in priority order (defined in `AppState+Status.swift`):

1. **Priority 0:** Accessibility not granted
2. **Priority 1:** Screen Recording not granted (if QuickEdit enabled)
3. **Priority 2:** Microphone not granted (if Transcription enabled)
4. **Priority 3:** Searchback keyboard issues (if Searchback enabled)
5. **Priority 4:** Typeahead disable status
6. **Priority 5:** All features disabled

### Status Messages

| Status | Display Text | Actionable |
|--------|--------------|------------|
| `accessibilityRequired` | "Grant Accessibility →" | Yes |
| `screenRecordingRequired` | "Grant Screen Recording →" | Yes |
| `microphoneRequired` | "Grant Microphone Access →" | Yes |
| `searchbackKeyboardNotAdded` | "Complete Setup →" | Yes |
| `searchbackKeyboardNotSelected` | "Switch input source →" | Yes |
| `running` | "Running" | No |

---

## Permission Flow

### First-Time Permission Request

```
User clicks "Grant Access"
         │
         ▼
┌─────────────────────────────┐
│ Check current status        │
│ (notDetermined/denied/etc)  │
└─────────────────────────────┘
         │
         ▼
    ┌────────────┐
    │notDetermined│───────────────┐
    └────────────┘                │
         │                        ▼
         │              ┌─────────────────────┐
         │              │ Show native dialog  │
         │              │ (system alert)      │
         │              └─────────────────────┘
         │                        │
         ▼                        ▼
    ┌────────────┐        ┌──────────────┐
    │  denied    │        │ User grants  │
    └────────────┘        │ or denies    │
         │                └──────────────┘
         ▼
┌─────────────────────────────┐
│ Open System Settings        │
│ (user must enable manually) │
└─────────────────────────────┘
```

### Permission State Monitoring

All permission managers use timer-based polling (0.5 second intervals) to detect when users grant permissions in System Settings:

```swift
// Example from AccessibilityPermissionManager
processTrustedTimer = Timer.scheduledTimer(
    timeInterval: 0.5,
    target: self,
    selector: #selector(checkProcessTrusted),
    userInfo: nil,
    repeats: true
)
```

This ensures the UI updates immediately when permissions change, even if the user grants them directly in System Settings.

---

## Conditional Permission Display

Some permissions are only displayed when their associated feature is enabled:

| Permission | Condition | Default Key |
|------------|-----------|-------------|
| Microphone | `transcriptionEnabled == true` | `Defaults[.transcriptionEnabled]` |
| Keyboard | `searchbackEnabled == true` | `Defaults[.searchbackEnabled]` |
| Screen Recording | `quickEditConfig.isEnabled == true` | `Defaults[.quickEditConfig]` |

---

## System Settings URLs

The app uses deep links to open specific System Settings sections:

### macOS 26+ (Tahoe)
```
x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility
x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture
x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone
```

### macOS < 26
```
x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility
x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture
x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone
```

---

## Testing Permissions

### Reset Permissions (Debug Builds)

```bash
# Reset all permissions for dev build
tccutil reset All inc.synth.onit.sidekick.dev

# Reset specific permission
tccutil reset Microphone inc.synth.onit.sidekick.dev
tccutil reset ScreenCapture inc.synth.onit.sidekick.dev
tccutil reset Accessibility inc.synth.onit.sidekick.dev

# Reset for production build
tccutil reset All inc.synth.onit.sidekick

# Reset for beta build
tccutil reset All inc.synth.onit.sidekick.beta
```

### Reset UserDefaults

```bash
defaults delete inc.synth.onit.sidekick.dev
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Entry Points                              │
├─────────────────┬─────────────────┬─────────────────────────────┤
│   Onboarding    │    Settings     │         Menu Bar            │
│                 │                 │                             │
│ - Accessibility │ - Setup page    │ - "Allow access..." item    │
│ - Permissions   │ - Sidekick      │ - Status message click      │
│   page          │   Context       │ - Status dot color          │
│                 │ - Sidekick      │                             │
│                 │   Behavior      │                             │
└────────┬────────┴────────┬────────┴──────────────┬──────────────┘
         │                 │                       │
         ▼                 ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Permission Managers                           │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  Accessibility  │ ScreenRecording │      Microphone             │
│  Permission     │ Permission      │      Input                  │
│  Manager        │ Manager         │      Manager                │
├─────────────────┼─────────────────┼─────────────────────────────┤
│ AXIsProcess     │ SCShareable     │ AVCaptureDevice             │
│ Trusted()       │ Content API     │ .requestAccess()            │
└────────┬────────┴────────┬────────┴──────────────┬──────────────┘
         │                 │                       │
         ▼                 ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      macOS Permission System                     │
├─────────────────┬─────────────────┬─────────────────────────────┤
│   Accessibility │  Screen         │      Microphone             │
│   TCC Database  │  Recording      │      TCC Database           │
│                 │  TCC Database   │                             │
└─────────────────┴─────────────────┴─────────────────────────────┘
```

---

## Related Files

| File | Description |
|------|-------------|
| `AppState+Status.swift` | Status computation, dot color, badge count |
| `MenuBarController.swift` | Menu bar permission checks, `anyPermissionMissing` |
| `MenuBarCheckForPermissions.swift` | "Allow access..." menu item |
| `OnboardingPermissions.swift` | Onboarding permission page |
| `SettingsSetup.swift` | Settings > Setup permission sections |
