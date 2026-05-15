cmake_minimum_required(VERSION 3.22.1)

project(vgmplayer)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 14)

# Android flags
add_definitions(-DANDROID -D__ANDROID__)

# Source placeholder (JNI comes in Phase 2)
add_library(vgmplayer SHARED
    vgm_stub.cpp
)

find_library(log-lib log)

target_link_libraries(vgmplayer
    ${log-lib}
)
