# Project Cleanup Guide

## Files You Can Safely Delete to Save Space

### Large Folders (Safe to Delete):

1. **`.dart_tool/`** - Dart tooling cache
   - Regenerates automatically when needed
   - Can save ~100-200 MB

2. **`build/`** - Build outputs and cache
   - ⚠️ **FIRST** copy `SVCE_Seating_Finder.apk` to a safe location
   - Then delete this folder
   - Can save ~500 MB - 1 GB

3. **`.idea/`** - Android Studio/IntelliJ settings
   - IDE-specific, regenerates automatically
   - Can save ~10-50 MB

4. **`android/.gradle/`** - Gradle cache
   - Regenerates on next build
   - Can save ~200-500 MB

### Files to Keep:

✅ `lib/` - Your source code  
✅ `android/app/src/` - Android configuration  
✅ `pubspec.yaml` - Dependencies  
✅ `icon.png` - App icon  
✅ `SVCE_Seating_Finder.apk` - Your final APK  
✅ `README.md` - Documentation (if exists)

## Quick Cleanup Commands

Run these in PowerShell from the project directory:

```powershell
# Remove build cache (after copying APK)
Remove-Item -Recurse -Force build

# Remove Dart tool cache
Remove-Item -Recurse -Force .dart_tool

# Remove IDE settings
Remove-Item -Recurse -Force .idea

# Remove Gradle cache
Remove-Item -Recurse -Force android\.gradle
```

## Estimated Space Savings

- **Before cleanup**: ~2-3 GB
- **After cleanup**: ~50-100 MB
- **APK only**: 53 MB

## To Rebuild Later

If you need to work on the project again:

1. Open the project in Android Studio or VS Code
2. Run `flutter pub get` to restore dependencies
3. The caches will regenerate automatically
4. Build with `flutter build apk --release`

## What Stays in the APK

The APK (53 MB) contains:
- Compiled Dart code
- Flutter framework
- Android libraries
- App resources (icons, etc.)
- PDF parsing library (Syncfusion)
- Background service libraries

This size is normal for a Flutter app with PDF processing capabilities.
