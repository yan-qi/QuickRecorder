# QuickRecorder - Build and Run Guide

This guide explains how to build and run the QuickRecorder app locally with the new temporary file implementation.

## 🔨 **Building the Local App**

### Method 1: Command Line Build

**Build the App Bundle:**
```bash
cd /Users/yqi/Documents/workspace/QuickRecorder

# Build for release (optimized)
xcodebuild -scheme QuickRecorder -configuration Release -archivePath QuickRecorder.xcarchive archive

# Export the app
xcodebuild -exportArchive -archivePath QuickRecorder.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
```

**Or build directly to Applications folder:**
```bash
# Build and copy to Applications (simpler approach)
xcodebuild -scheme QuickRecorder -configuration Release SYMROOT=./build
cp -R ./build/Release/QuickRecorder.app /Applications/
```

### Method 2: Build via Xcode GUI

**1. Open Project:**
```bash
open QuickRecorder.xcodeproj
```

**2. Archive the App:**
- Select `Product → Archive`
- When archive completes, click "Distribute App"
- Choose "Copy App" 
- Select destination folder (e.g., Desktop)

## 🏃 **Running the Local App**

### Method 1: Direct Launch
```bash
# Run from build directory
./build/Release/QuickRecorder.app/Contents/MacOS/QuickRecorder

# Or if installed in Applications
/Applications/QuickRecorder.app/Contents/MacOS/QuickRecorder
```

### Method 2: Using `open` Command
```bash
# Launch the app bundle
open ./build/Release/QuickRecorder.app

# Or from Applications
open /Applications/QuickRecorder.app
```

### Method 3: Double-click
- Navigate to the `.app` bundle in Finder
- Double-click to launch

## ⚙️ **Required Setup for Local App**

### 1. Grant Permissions

**Screen Recording permission:**
- Go to: System Preferences → Security & Privacy → Privacy → Screen Recording
- Add QuickRecorder.app to the list

**Camera permission (if using camera features):**
- Go to: System Preferences → Security & Privacy → Privacy → Camera
- Add QuickRecorder.app to the list

**Microphone permission (if using audio recording):**
- Go to: System Preferences → Security & Privacy → Privacy → Microphone
- Add QuickRecorder.app to the list

### 2. Handle Code Signing Issues

If you get "unidentified developer" warnings:
```bash
# Remove quarantine attribute
xattr -rd com.apple.quarantine /Applications/QuickRecorder.app

# Or allow in System Preferences
# System Preferences → Security & Privacy → General → "Allow apps downloaded from: Anywhere"
```

## 🧪 **Testing Your Temporary File Implementation**

### 1. Set Save Directory
- Launch QuickRecorder
- Go to Settings and set your preferred save directory (e.g., Desktop)

### 2. Test Recording
```bash
# Monitor the temp directory during recording
watch -n 1 "ls -la ~/Desktop/.tmp/"

# Start a screen recording and observe:
# - .tmp/ folder creation
# - Temporary files appearing during recording
# - Files moving to final location when complete
```

### 3. Test Cleanup
```bash
# Force quit during recording
pkill QuickRecorder

# Check temp files exist
ls -la ~/Desktop/.tmp/

# Restart app and verify cleanup
open /Applications/QuickRecorder.app
sleep 2
ls -la ~/Desktop/.tmp/  # Should be empty
```

## 🔍 **Debug the Local App**

### View Console Logs
```bash
# Monitor app logs in real-time
log stream --predicate 'subsystem contains "QuickRecorder"' --level debug

# Or check Console.app for QuickRecorder logs
open /Applications/Utilities/Console.app
```

### Monitor File System Activity
```bash
# Watch file operations
sudo fs_usage -w -f filesys QuickRecorder
```

## 📦 **Create Distributable Package**

### Create DMG (Optional)
```bash
# Install create-dmg if needed
brew install create-dmg

# Create DMG
create-dmg \
  --volname "QuickRecorder" \
  --window-pos 200 120 \
  --window-size 600 300 \
  --icon-size 100 \
  --app-drop-link 425 120 \
  "QuickRecorder.dmg" \
  "./build/Release/"
```

## 🚨 **Troubleshooting Local App Issues**

### App Won't Launch
- Check Console.app for crash logs
- Verify all frameworks are included in the bundle
- Check code signing and permissions

### Recording Fails
- Ensure Screen Recording permission is granted
- Check save directory is writable
- Monitor logs for temp directory creation errors

### Temp Files Not Working
- Check the logs for "Moving recording from..." messages
- Verify `.tmp/` directory creation in save folder
- Test with different save directory locations

## 🎯 **What to Expect with Temporary File Implementation**

### During Recording
- `.tmp/` folder is created in your save directory
- Recording files are saved with names like `recording_[UUID].mp4` in the temp folder
- No files appear in the main save directory until recording completes

### After Recording Completes
- Files are atomically moved from `.tmp/` to final location
- Final files have proper timestamp names like `Recording at 2024-01-01 12.00.00.mp4`
- `.tmp/` folder is cleaned up

### On App Restart
- Any leftover temporary files from crashed recordings are automatically cleaned up
- Fresh `.tmp/` folder is ready for new recordings

### Key Benefits
- **Atomic Operations**: Users only see complete, valid recordings
- **Crash Recovery**: No partial files left in destination folder
- **Concurrent Safety**: Multiple recordings use unique temporary files

---

Your local QuickRecorder app will now use the temporary file system, providing atomic recording operations! 🎉