cmake_minimum_required(VERSION 3.7)
project(DarkGalgame)

set(CMAKE_CXX_STANDARD 11)

include_directories(
        wine-2.8/include
        wine-2.8/include/wine
        qemu-2.8.0
        qemu-2.8.0/include
        qemu-2.8.0/tcg
        qemu-2.8.0/tcg/arm
        qemu-2.8.0/target-i386
        qemu-2.8.0/linux-headers
        /home/fallenworld/dev/android/build/sysroot/usr/include
        /home/fallenworld/dev/android/build/sysroot/usr/include/glib-2.0
        /home/fallenworld/dev/android/build/sysroot/usr/include/libpng12
)

set(SOURCE_FILES )


aux_source_directory(bridge SOURCE_FILES)
aux_source_directory(qemu-2.8.0/linux-user SOURCE_FILES)
aux_source_directory(qemu-2.8.0/android SOURCE_FILES)
aux_source_directory(qemu-2.8.0 SOURCE_FILES)
aux_source_directory(wine-2.8/server SOURCE_FILES)
aux_source_directory(wine-2.8/loader SOURCE_FILES)
aux_source_directory(wine-2.8/libs/wine SOURCE_FILES)
aux_source_directory(wine-2.8/dlls/ntdll SOURCE_FILES)
aux_source_directory(wine-2.8/dlls/kernel32 SOURCE_FILES)

add_executable(DarkGalgame ${SOURCE_FILES})