# Phase 1: Native Build Setup - Complete ✅

## 📦 Files Created

1. **CMakeLists.txt** (270 lines)
   - Configures 7 audio libraries (libvgm, libgme, libopenmpt, libkss, libADLMIDI, libMusDoom, libpsf)
   - Handles patch application at build time
   - Resolves symbol conflicts (emu2413)
   - Builds vgmplayer native library

2. **init_submodules.sh** (executable)
   - Initializes all git submodules
   - Downloads library sources automatically

3. **prepare_libvgm_source.sh** (executable)
   - Applies libvgm patches if they exist in patches/ directory

4. **prepare_libkss_source.sh** (executable)
   - Applies libkss patches if they exist in patches/ directory

---

## 🚀 Next: Build Phase 1

### Step 1: Initialize Submodules
```bash
cd app/src/main/cpp
bash init_submodules.sh
git submodule update --init --recursive
```

This downloads:
- libvgm (VGM/VGZ support)
- libgme (NSF/GBS/SPC support)
- libopenmpt (Tracker support)
- libkss (KSS/MSX support)
- libADLMIDI (MIDI support)
- libMusDoom (Doom MUS support)
- libpsf (PSF support)

### Step 2: Apply Patches
```bash
bash prepare_libvgm_source.sh
bash prepare_libkss_source.sh
```

### Step 3: Build APK
```bash
cd /path/to/OuterTune-VGM
./gradlew assembleDebug
```

**Expected build time:** 15-30 minutes (first build is longer)

### Step 4: Verify
```bash
# Check if native library was built
unzip -l build/outputs/apk/debug/app-debug.apk | grep libvgmplayer
```

You should see multiple entries like:
```
lib/arm64-v8a/libvgmplayer.so
lib/x86_64/libvgmplayer.so
lib/armeabi-v7a/libvgmplayer.so
lib/x86/libvgmplayer.so
```

---

## 📋 Gradle Configuration

**app/build.gradle.kts** includes:
- NDK filters: arm64-v8a, x86_64, armeabi-v7a, x86
- CMake version: 3.22.1
- C++ flags: C++14 standard
- External native build: src/main/cpp/CMakeLists.txt

---

## ⚠️ Troubleshooting

### "CMake version 3.22.1 or higher is not found"
→ Update Android Studio or install CMake via SDK Manager

### "git submodule: directory already exists"
→ Already initialized, proceed to next step

### Build fails with "patch not found"
→ No patches in patches/ directory yet (normal for first run)

### Linking error: "multiple definition of `emu2413'"
→ Already handled by CMakeLists.txt, should not occur

---

## 📊 Phase 1 Status

- ✅ CMakeLists.txt created
- ✅ Gradle updated
- ✅ Setup scripts created
- ⏳ **Ready for first build**

---

## 📝 Notes

- Submodules are pinned to specific commits (stable versions)
- All libraries built as static (no external dependencies)
- APK will increase by ~8-12MB for all native libraries
- First build downloads ~500MB of library source code

---

## Next Phase: Phase 2 (JNI Bridge)

Once Phase 1 builds successfully, Phase 2 will create:
- `vgmplayer_jni.cpp` - JNI implementation
- Native method declarations for Kotlin
- Format detection and routing logic

**Ready to start Phase 1 build? Follow the steps above!** 🚀
