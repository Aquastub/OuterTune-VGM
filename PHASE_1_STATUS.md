# Phase 1: Native Build Setup - Status Checklist

## ✅ Completed

### 1.1 CMakeLists.txt Created
- [x] CMake minimum version set to 3.22.1
- [x] C/C++ standards configured (C99, C++14)
- [x] Android-specific compiler flags added
- [x] All 7 audio libraries configured as submodules:
  - libvgm (VGM/VGZ)
  - libgme (NSF/GBS/SPC/etc)
  - libopenmpt (Trackers)
  - libkss (MSX/KSS)
  - libADLMIDI (MIDI)
  - libMusDoom (Doom MUS)
  - libpsf (PSF)
- [x] Patch system implemented (auto-applies patches at build time)
- [x] Symbol conflict resolution (emu2413)
- [x] vgmplayer shared library target defined

### 1.2 Gradle Build Configuration Updated
- [x] NDK configuration added (arm64-v8a, x86_64, armeabi-v7a, x86)
- [x] CMake external native build configured
- [x] CMake version set to 3.22.1
- [x] Compiler flags and arguments passed to CMake
- [x] Updated app/build.gradle.kts with VGM build settings

### 1.3 Setup Scripts Created
- [x] `init_submodules.sh` - Initializes all git submodules
- [x] `prepare_libvgm_source.sh` - Applies libvgm patches
- [x] `prepare_libkss_source.sh` - Applies libkss patches

### 1.4 Documentation
- [x] `README.md` - Build instructions and overview

---

## ⏭️ Next Steps for Implementation

### Step 1: Initialize Submodules
```bash
cd app/src/main/cpp
bash init_submodules.sh
git submodule update --init --recursive
```

### Step 2: Apply Patches
```bash
bash prepare_libvgm_source.sh
bash prepare_libkss_source.sh
```

### Step 3: Test Build
```bash
cd /path/to/OuterTune-VGM
./gradlew assembleDebug
```

**Expected Output:**
- CMake configures 7 audio libraries
- Patches applied (if any exist in patches/ directory)
- vgmplayer native library built for all ABIs
- APK includes libvgmplayer.so for all architectures

### Step 4: Verify Native Library
```bash
# Check if native library was built
unzip -l build/outputs/apk/debug/app-debug.apk | grep libvgmplayer
# Should show: lib/arm64-v8a/libvgmplayer.so, lib/x86_64/libvgmplayer.so, etc.
```

---

## 📋 Troubleshooting

### CMake not found
```
Error: CMake version 3.22.1 or higher is not found
```
**Fix:** Update Android Studio or install CMake 3.22.1+ via SDK Manager

### Submodule conflicts
```
Error: git submodule add: directory already exists
```
**Fix:** `git rm --cached <directory>` then retry

### Build fails on first run
**Common causes:**
1. Patches not applied - Run `prepare_libvgm_source.sh` and `prepare_libkss_source.sh`
2. Submodules not initialized - Run `git submodule update --init --recursive`
3. NDK not installed - Install via Android Studio SDK Manager

### Symbol conflicts during linking
```
Error: multiple definition of `emu2413'
```
**Fix:** Already handled by CMakeLists.txt with `-Wl,--allow-multiple-definition`

---

## 📦 Phase 1 Artifacts

Files created:
- ✅ `app/src/main/cpp/CMakeLists.txt` (270 lines)
- ✅ `app/build.gradle.kts` (updated with NDK/CMake config)
- ✅ `app/src/main/cpp/init_submodules.sh` (executable)
- ✅ `app/src/main/cpp/prepare_libvgm_source.sh` (executable)
- ✅ `app/src/main/cpp/prepare_libkss_source.sh` (executable)
- ✅ `app/src/main/cpp/README.md` (documentation)

---

## 🎯 Phase 2: Ready to Begin

Once Phase 1 builds successfully, proceed to **Phase 2: JNI Bridge Layer**

Phase 2 will create:
- `app/src/main/cpp/vgmplayer_jni.cpp` (~95KB)
- JNI method declarations for Kotlin
- Format detection and routing logic

**Estimated time for Phase 1 complete build:** 15-30 minutes (first build takes longer due to downloading libraries)

---

## 📝 Notes

- Git submodules are pinned to specific commits in VGMP for stability
- Patches handle Android-specific build issues
- No external audio dependencies needed (everything statically linked)
- APK will increase by ~8-12MB for native libraries

