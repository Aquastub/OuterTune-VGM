# VGM Integration Plan for OuterTune-VGM

## Overview
This document outlines how to integrate native VGM format support into OuterTune-VGM by adapting the proven architecture from VGMP (niekvlessert/vgmp). The plan focuses on playback and metadata extraction first, with advanced features (audio effects, per-channel control) deferred.

---

## 1. Architecture Overview

### Key Components

```
OuterTune-VGM (Kotlin/Android)
├── app/src/main/cpp/                     # Native C++ layer
│   ├── CMakeLists.txt                    # Build configuration
│   ├── libvgm/                           # Git submodule (VGM/VGZ support)
│   ├── libgme/                           # Git submodule (NSF/GBS/SPC/etc)
│   ├── libopenmpt/                       # Git submodule (Tracker formats)
│   ├── libkss/                           # Git submodule (KSS/MSX)
│   ├── libADLMIDI/                       # Git submodule (MIDI)
│   ├── libMusDoom/                       # Git submodule (Doom MUS)
│   ├── libpsf/                           # Git submodule (PSF/PS1)
│   ├── patches/                          # Platform-specific patches
│   └── vgmplayer_jni.cpp                 # JNI bridge to engines
│
├── app/src/main/kotlin/.../media/
│   ├── decoder/
│   │   ├── VgmDecoder.kt                 # Media3 Decoder impl
│   │   ├── VgmDecoderFactory.kt          # Factory
│   │   └── VgmAudioProcessor.kt          # Audio processing
│   ├── metadata/
│   │   ├── VgmMetadataExtractor.kt       # Metadata extraction
│   │   └── VgmTagParser.kt               # Tag parsing
│   ├── engine/
│   │   ├── VgmEngine.kt                  # Singleton JNI wrapper
│   │   ├── VgmTags.kt                    # Tag data class
│   │   └── VgmAudioBuffer.kt             # PCM buffer management
│   └── renderer/
│       └── VgmAudioRenderer.kt           # Media3 Renderer impl
│
└── app/src/main/AndroidManifest.xml      # Register format MIME types
```

---

## 2. Step-by-Step Implementation

### Phase 1: Native Build Setup

#### Step 1.1: Add CMake Configuration
Create `app/src/main/cpp/CMakeLists.txt`:
- Configure C++14 standard with Android-specific flags
- Add git submodule dependencies for: libvgm, libgme, libopenmpt, libkss, libADLMIDI, libMusDoom, libpsf
- Apply platform-specific patches before building
- Link all libraries into single `vgmplayer` shared library
- Handle symbol conflicts (libgme's emu2413 vs libkss's emu2413)

**Key settings from VGMP:**
```cmake
set(CMAKE_CXX_STANDARD 14)
set(UTIL_CHARSET_CONV OFF)  # libvgm
set(GME_BUILD_STATIC ON)    # libgme
set(LIBADLMIDI_STATIC ON)   # libADLMIDI
target_link_options(vgmplayer PRIVATE "-Wl,--allow-multiple-definition")
```

#### Step 1.2: Update Gradle Configuration
Modify `app/build.gradle.kts`:
```kotlin
android {
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
    
    defaultConfig {
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64", "armeabi-v7a", "x86")
        }
    }
}
```

#### Step 1.3: Add Git Submodules
```bash
cd app/src/main/cpp
git submodule add https://github.com/ValleyBell/libvgm.git libvgm
git submodule add https://github.com/libgme/game-music-emu.git libgme
git submodule add https://github.com/OpenMPT/openmpt.git libopenmpt
git submodule add https://github.com/digital-sound-antiques/libkss.git libkss
git submodule add https://github.com/Wohlstand/libADLMIDI.git libADLMIDI
git submodule add https://github.com/Wohlstand/libMusDoom.git libMusDoom
git submodule add https://github.com/CoreDumpling/sexypsf.git libpsf
git submodule update --init --recursive
```

---

### Phase 2: JNI Bridge Layer

#### Step 2.1: Create JNI Wrapper (`app/src/main/cpp/vgmplayer_jni.cpp`)

This ~95KB file handles:

**Initialization:**
- `nSetSampleRate(rate)` - Set output sample rate
- `nSetRomPath(path)` - ROM path for games needing cartridge dumps

**Playback Control:**
- `nOpen(path)` - Load VGM file
- `nClose()` - Cleanup
- `nPlay()` - Start playback
- `nStop()` - Stop playback
- `nSeek(samplePos)` - Seek to position
- `nFillBuffer(ShortArray buffer, frames)` - Get audio data (returns frames written)

**Metadata Extraction:**
- `nGetTags()` - Return "TITLE|||value|||GAME|||value|||..." format
- `nGetTotalSamples()` - Track duration in samples
- `nGetCurrentSample()` - Current playback position
- `nIsEnded()` - Track end detection

**Multi-track Support (NSF/GBS):**
- `nGetTrackCount()` - Number of subtracks
- `nSetTrack(index)` - Switch to subtrack
- `nGetCurrentTrack()` - Current subtrack
- `nIsMultiTrack(path)` - Check if file has subtracks

**Device Information (per-channel later):**
- `nGetDeviceCount()` - Number of sound chips
- `nGetDeviceName(id)` - Chip name (e.g., "YM2612")

---

### Phase 3: Kotlin Engine Wrapper

#### Step 3.1: Create `VgmEngine.kt`

Singleton wrapper around JNI with Coroutine-safe synchronization:

```kotlin
object VgmEngine {
    private val mutex = Mutex()
    
    init {
        System.loadLibrary("vgmplayer")
    }
    
    // Native declarations
    @JvmStatic external fun nOpen(path: String): Boolean
    @JvmStatic external fun nGetTags(): String
    // ... (all JNI methods)
    
    // Thread-safe wrappers
    suspend fun open(path: String): Boolean = mutex.withLock { nOpen(path) }
    suspend fun getTags(): String = mutex.withLock { nGetTags() }
    
    fun parseTags(raw: String): VgmTags {
        // Parse "KEY|||value|||KEY2|||value2" format
    }
}
```

**Key Features:**
- Mutex-based synchronization prevents race conditions between render thread and UI
- Suspend functions for coroutine compatibility
- Tag parsing utility that converts JNI string format to data class

#### Step 3.2: Create `VgmTags.kt`

Data class for parsed metadata:

```kotlin
data class VgmTags(
    val trackEn: String = "",
    val trackJp: String = "",
    val gameEn: String = "",
    val gameJp: String = "",
    val systemEn: String = "",
    val systemJp: String = "",
    val authorEn: String = "",
    val authorJp: String = "",
    val date: String = "",
    val creator: String = "",
    val notes: String = ""
) {
    val displayTitle: String
    val displayGame: String
    val displaySystem: String
    val displayAuthor: String
}
```

---

### Phase 4: Media3 Integration

#### Step 4.1: Create `VgmDecoderFactory.kt`

Registers VGM format with Media3:

```kotlin
class VgmDecoderFactory : Decoder.Factory {
    override fun supportsFormat(format: Format): Boolean {
        return format.sampleMimeType in listOf(
            "audio/vgm", "audio/vgz",  // VGM
            "audio/nsf", "audio/nsfe", // NES
            "audio/gbs",               // Game Boy
            "audio/spc",               // SNES
            "audio/kss",               // MSX
            // ... all supported formats
        )
    }
    
    override fun createAudioDecoder(format: Format): AudioDecoder {
        return VgmDecoder(format)
    }
}
```

#### Step 4.2: Create `VgmAudioRenderer.kt`

Implements Media3's `Renderer`:

```kotlin
class VgmAudioRenderer : Renderer {
    override fun render(positionUs: Long, elapsedRealtimeUs: Long) {
        // Fill audio buffers from VgmEngine
        val frames = VgmEngine.fillBuffer(audioBuffer, framesToRender)
        // Write to audio sink
    }
    
    override fun setCurrentStreamFinal() {
        // Mark end of stream
    }
}
```

#### Step 4.3: Create `VgmMetadataExtractor.kt`

Implements Media3's metadata extraction:

```kotlin
class VgmMetadataExtractor : MetadataExtractor {
    override fun extract(input: DataReader, seekMap: SeekMap?): Metadata? {
        val path = input.uri // Get file path
        if (!VgmEngine.open(path)) return null
        
        val tagsRaw = VgmEngine.getTags()
        val tags = VgmEngine.parseTags(tagsRaw)
        val duration = VgmEngine.getTotalSamples()
        
        return Metadata().apply {
            set(0, StandardMetadata(
                title = tags.displayTitle,
                artist = tags.displayAuthor,
                albumTitle = tags.displayGame,
                genre = tags.displaySystem,
                // ... other fields
            ))
        }
    }
}
```

---

### Phase 5: Format Registration

#### Step 5.1: Update `AndroidManifest.xml`

Register supported MIME types:

```xml
<application>
    <service android:name=".media.VgmPlaybackService">
        <intent-filter>
            <action android:name="android.media.browse.MediaBrowserService" />
        </intent-filter>
    </service>
    
    <!-- VGM format support -->
    <meta-data
        android:name="supported_formats"
        android:value="vgm,vgz,nsf,nsfe,gbs,spc,kss,ay,sap,gym,hes,mod,xm,s3m,it,mid,midi" />
</application>
```

#### Step 5.2: Update File Type Detection

In Media3 configuration:

```kotlin
val renderer = DefaultRenderersFactory(context)
    .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)
    .buildRenderers(...)

// Add VGM renderer factory
renderers.add(VgmAudioRenderer())
```

---

## 3. Implementation Priority

### Must-Have (MVP)
1. ✅ Native build setup (CMakeLists.txt, submodules)
2. ✅ VGM/VGZ playback via libvgm
3. ✅ Basic metadata extraction (title, game, system)
4. ✅ Seek support
5. ✅ Format registration with OuterTune

### Should-Have (v2)
- Multi-track support (NSF, GBS)
- Enhanced metadata (artist, date, notes)
- Duration detection for all formats
- Format-specific icon overlays

### Nice-to-Have (v3+)
- Per-channel volume control
- Audio visualizer integration
- Bass boost / reverb effects
- Slow playback for learning
- VGM download integration

---

## 4. Testing Checklist

### Build Tests
- [ ] CMake builds without errors (arm64-v8a, x86_64)
- [ ] All submodules compile
- [ ] No symbol conflicts (emu2413 linking)
- [ ] APK size within bounds

### Playback Tests
- [ ] VGM files play without crashes
- [ ] VGZ (compressed) files decompress and play
- [ ] Seek works accurately
- [ ] Multi-track files play all tracks

### Metadata Tests
- [ ] Titles extracted correctly
- [ ] Game names match metadata
- [ ] Duration calculations accurate
- [ ] Japanese characters display properly

### Integration Tests
- [ ] OuterTune recognizes VGM files
- [ ] Playlist supports mixed formats (MP3 + VGM)
- [ ] File browser shows VGM files
- [ ] Playback seamlessly switches between formats

---

## 5. Key Differences from VGMP

| Aspect | VGMP | OuterTune-VGM |
|--------|------|--------------|
| **Architecture** | Standalone app | Integration into existing player |
| **UI Framework** | Android Views | Jetpack Compose |
| **Dependencies** | Minimal | Inherits OuterTune's (Media3, Hilt, etc.) |
| **File Selection** | Local file picker | Uses OuterTune's library scanner |
| **Metadata Store** | Room database | OuterTune's existing database |
| **Playback Control** | Custom | Media3 ExoPlayer framework |
| **Scope (Phase 1)** | Full feature set | Playback + metadata only |

---

## 6. Potential Issues & Solutions

### Issue 1: Symbol Conflicts
**Problem:** libgme and libkss both define `emu2413`
**Solution:** Use CMake linker option: `-Wl,--allow-multiple-definition`

### Issue 2: File Path Encoding
**Problem:** VGM files with Unicode names might not load
**Solution:** JNI layer must properly convert Java String → UTF-8 C string

### Issue 3: Memory Usage
**Problem:** Loading very large VGM files (~10MB+) could exhaust memory
**Solution:** Implement streaming decoder or file size checks

### Issue 4: Seeking Accuracy
**Problem:** Some VGM formats have complex seek tables
**Solution:** Use engine's native `nSeek()` for accuracy, validate with `nGetCurrentSample()`

---

## 7. Reference Implementation

**VGMP Repository:** https://github.com/niekvlessert/vgmp

Use these files as reference:
- `CMakeLists.txt` - Build configuration
- `app/build.gradle.kts` - Gradle setup
- `app/src/main/cpp/vgmplayer_jni.cpp` - JNI implementation (~95KB)
- `app/src/main/java/org/vlessert/vgmp/engine/VgmEngine.kt` - Kotlin wrapper

---

## 8. Next Steps

1. **Create feature branch:** `feature/vgm-support`
2. **Set up CMake build:** Implement Phase 1 & 2
3. **Test native compilation:** Build APK with VGM support
4. **Create Kotlin wrappers:** Implement Phase 3
5. **Integrate with Media3:** Implement Phase 4
6. **Register formats:** Implement Phase 5
7. **Test playback:** Run against sample VGM files
8. **Update OuterTune UI:** Show VGM-specific metadata

---

## 9. Resources

- libvgm: https://github.com/ValleyBell/libvgm
- Game Music Emu (libgme): https://github.com/libgme/game-music-emu
- Media3 Decoder API: https://developer.android.com/media/implement-playback/progressive-download#implement-decoders
- Android NDK Guide: https://developer.android.com/ndk/guides

