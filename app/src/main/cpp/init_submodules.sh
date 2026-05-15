#!/usr/bin/env bash
set -e

echo "Initializing submodules..."

git submodule add https://github.com/ValleyBell/libvgm.git libvgm || true
git submodule add https://github.com/libgme/game-music-emu.git libgme || true
git submodule add https://github.com/OpenMPT/openmpt.git libopenmpt || true
git submodule add https://github.com/digital-sound-antiques/libkss.git libkss || true
git submodule add https://github.com/Wohlstand/libADLMIDI.git libADLMIDI || true
git submodule add https://github.com/Wohlstand/libMusDoom.git libMusDoom || true
git submodule add https://github.com/MusicPlayerDaemon/libpsf.git libpsf || true

echo "Done."
