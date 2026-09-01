# EasyBar App Store Checklist

## Current App Store-Friendly Scope

- Uses public macOS APIs only.
- Lists running applications through `NSWorkspace.shared.runningApplications`.
- Does not request screen recording, input monitoring, accessibility, file access, network access, or automation permissions.
- Includes a minimal App Sandbox entitlement file at `Sources/EasyBar/Resources/EasyBar.entitlements`.
- Provides a local signed `.app` bundle through `script/build_and_run.sh`.
- Includes a placeholder App Icon asset catalog at `Sources/EasyBar/Resources/Assets.xcassets`.

## Required Before Submission

1. Install full Xcode and select it with `xcode-select`.
2. Open `EasyBar.xcodeproj`.
3. Sign in to Xcode with an Apple Developer account.
4. Select the `EasyBar` target and choose your Team under Signing & Capabilities.
5. Create an Apple Developer App ID for `com.jiangcheng.EasyBar` or update the bundle identifier.
6. Keep Automatically manage signing enabled so Xcode can create the provisioning profile.
7. Confirm App Sandbox is enabled through `Sources/EasyBar/Resources/EasyBar.entitlements`.
8. Configure a Mac App Store distribution certificate and provisioning profile.
9. Add production metadata:
   - App icon set.
   - Version and build numbers.
   - Copyright string.
   - App category.
   - Privacy Nutrition Labels stating no data collection for this first version.
10. Archive with Xcode Organizer, validate, and upload to App Store Connect.

## Current Local Status

- `EasyBar.xcodeproj` exists and has a `EasyBar` macOS target and shared scheme.
- Xcode Debug build succeeds with Team `M3A6LK593A`.
- Xcode Release archive succeeds.
- App Store Connect export succeeds and produces `build/export/EasyBar.pkg`.
- The exported package uses `Cloud Managed Apple Distribution`.
- The exported app uses `Mac Team Store Provisioning Profile: com.jiangcheng.EasyBar`.
- App Store Connect upload succeeds. The uploaded package is processing.

## Create App Store Connect App Record

In App Store Connect, create a new macOS app with:

- Platform: macOS
- Name: EasyBar
- Bundle ID: `com.jiangcheng.EasyBar`
- SKU: `easybar-001`
- User Access: Full Access

To upload another build, run:

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -exportArchive -archivePath build/EasyBar.xcarchive -exportPath build/upload -exportOptionsPlist ExportOptionsUpload.plist -allowProvisioningUpdates
```

## Important Constraint

This first version intentionally avoids global hotkeys because App Store-safe global shortcut handling can require extra permissions or additional review explanation. The implemented shortcuts work while EasyBar is active:

- `Command R`: refresh running apps.
- `Command Shift H`: hide EasyBar.
- `Command F`: search.
- `Command W`: close window.
