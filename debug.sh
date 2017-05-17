#!/bin/bash

#Created by fallenworld
#email:fallenworlder@gmail.com

SDK=~/dev/android/sdk
NDK=~/dev/android/ndk
ANDROID_BUILD=~/dev/android/build
export PATH=$PATH:$SDK/platform-tools:$NDK:$ANDROID_BUILD/bin

SYSROOT=$ANDROID_BUILD/sysroot
HOSTWINE=~/download/wine/winex86
SCRIPT_PATH=$(cd `dirname $0`; pwd)
HOST=arm-linux-androideabi
CC=$HOST-gcc
CXX=$HOST-g++
CFLAGS="-g -O2 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fPIE -pie -fPIC -Wno-missing-prototypes -Wno-strict-prototypes -Wno-old-style-definition"
CXXFLAGS="-std=c++11"
LIBDIRS="-L$ANDROID_BUILD/arm-linux-androideabi/lib"
PKG_CONFIG_PATH="$SYSROOT/usr/lib/pkgconfig"
QEMU_LDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8,-soname,libqemu.so $LIBDIRS -fPIE -pie -fPIC -shared"
QEMU_CONFLAGS="--prefix=${SYSROOT}/usr --cross-prefix=${HOST}- --host-cc=$CC --target-list=i386-linux-user --cpu=arm --disable-system --disable-bsd-user --disable-tools --disable-zlib-test --disable-guest-agent --disable-nettle --enable-debug"
WINE_LDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8 $LIBDIRS"
WINE_CONFLAGS="--prefix=${SYSROOT}/usr --host=$HOST host_alias=$HOST --with-wine-tools=$HOSTWINE --without-x --without-freetype -without-capi --without-tiff"
APPDIR=application
JNILIBSDIR=$APPDIR/app/src/main/jniLibs/armeabi-v7a
APPNAME=org.fallenworld.darkgalgame
QEMU_FILE=qemu-2.8.0/i386-linux-user/qemu-i386
WINE_DLL="wine-2.8/dlls/ntdll/ntdll.dll.so wine-2.8/dlls/kernel32/kernel32.dll.so"
WINE_FILE="wine-2.8/loader/wine wine-2.8/server/wineserver wine-2.8/libs/wine/libwine.so $WINE_DLL"
LOGMONITOR=bridge/logMonitor
GDBSERVER=$NDK/prebuilt/android-arm/gdbserver/gdbserver
GDB_PORT=2333
PID=
GDBSERVER_PID=
CONSOLE=konsole

function compileMonitor()
{
    $CC -o bridge/logMonitor bridge/logMonitor.c -Iinclude -pie
}

function compileQemu()
{
    cd qemu-2.8.0
    if [ ! -s $ANDROID_BUILD/bin/arm-linux-androideabi-pkg-config ]
    then
        ln -s /usr/bin/pkg-config $ANDROID_BUILD/bin/arm-linux-androideabi-pkg-config
    fi
    if [ $1 = rebuild ]
    then
        make clean
        make distclean
        PKG_CONFIG_PATH=$PKG_CONFIG_PATH CC=$CC CXX=$CXX CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$QEMU_LDFLAGS" ./configure $QEMU_CONFLAGS &&
        make -j4
    else
        make -j4
    fi
    if [ ! $? = 0 ]
    then
        exit 1
    fi
    #cp -fv i386-linux-user/qemu-i386 ../$JNILIBSDIR/libqemu.so
    cp -fv i386-linux-user/qemu-i386 ../debugSysRoot/data/data/$APPNAME/libqemu.so
    cd ..
}

function compileWine()
{
    cd wine-2.8
    if [ ! -s $ANDROID_BUILD/bin/arm-linux-androideabi-pkg-config ]
    then
        ln -s /usr/bin/pkg-config $ANDROID_BUILD/bin/arm-linux-androideabi-pkg-config
    fi
    if [ $1 = rebuild ]
    then
        make clean
        make distclean
        CC=$CC CXX=$CXX CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$WINE_LDFLAGS" ./configure $WINE_CONFLAGS &&
        make -j4
    else
        make -j4
    fi
    if [ ! $? = 0 ]
    then
        exit 1
    fi
    cp -fv loader/wine ../debugSysRoot/data/data/$APPNAME/wine
    cp -fv server/wineserver ../debugSysRoot/data/data/$APPNAME/wineserver
    cp -fv libs/wine/libwine.so ../debugSysRoot/data/data/$APPNAME/libwine.so
    cd ..
}

case $1 in

install)
    cd $APPDIR
    ./gradlew installDebug
;;

build|rebuild)
    compileMonitor
    #compileQemu
    compileWine $1

    #Push dynamic lib, gdb server, log monitor
    echo "Pushing qemu-i386 ,wine files and logMonitor to android target:"
    adb push $QEMU_FILE /data/local/tmp/
    adb push $WINE_FILE /data/local/tmp/
    adb push $LOGMONITOR /data/local/tmp/
    if [ ! $(adb shell ls /data/local/tmp | grep gdbserver) ]
    then
        echo "Pushing gdbserver to android target:"
        adb push $GDBSERVER /data/local/tmp/gdbserver
    fi
    echo "run-as $APPNAME" > .adbShellCmd
    echo "cp -fv /data/local/tmp/qemu-i386 libqemu.so" >> .adbShellCmd
    echo "cp -fv /data/local/tmp/wine wine" >> .adbShellCmd
    echo "cp -fv /data/local/tmp/wineserver wineserver" >> .adbShellCmd
    echo "cp -fv /data/local/tmp/libwine.so libwine.so" >> .adbShellCmd
    echo "cp -fv /data/local/tmp/ntdll.dll.so ntdll.dll.so" >> .adbShellCmd
    echo "cp -fv /data/local/tmp/kernel32.dll.so kernel32.dll.so" >> .adbShellCmd
    echo "cp -fv /data/local/tmp/logMonitor logMonitor" >> .adbShellCmd
    echo "cp -fv /data/local/tmp/gdbserver gdbserver" >> .adbShellCmd
    echo "chmod 777 libqemu.so" >> .adbShellCmd
    echo "chmod 777 wine" >> .adbShellCmd
    echo "chmod 777 libwine.so" >> .adbShellCmd
    echo "chmod 777 wineserver" >> .adbShellCmd
    echo "chmod 777 ntdll.dll.so" >> .adbShellCmd
    echo "chmod 777 kernel32.dll.so" >> .adbShellCmd
    echo "chmod 777 logMonitor" >> .adbShellCmd
    echo "chmod 777 gdbserver" >> .adbShellCmd
    adb shell < .adbShellCmd
;;

clean)
    cd qemu-2.8.0
    make clean
    cd ..
    cd wine-2.8
    make clean
    cd ..
;;

run)
    #Start APP
    adb shell am start -n $APPNAME/$APPNAME.MainActivity -a android.intent.action.MAIN -c android.intent.category.LAUNCHER

    #Get APP process ID
    PID=$(adb shell ps | grep $APPNAME | awk {'print $2'})

    #Start GDB server
    adb forward tcp:$GDB_PORT tcp:$GDB_PORT
    echo "Starting GDB server:"
    echo "run-as $APPNAME" > .adbShellCmd
    echo "./gdbserver :$GDB_PORT --attach $PID" >> .adbShellCmd
    adb shell < .adbShellCmd &
;;

stop)
    #Stop APP
    echo "Stop APP"
    PID=$(adb shell ps | grep $APPNAME | awk {'print $2'})
    echo "run-as $APPNAME" > .adbShellCmd
    echo "kill -s SIGKILL $PID" >> .adbShellCmd
    #echo "kill -s $SIG_END_DEBUG $PID" >> .adbShellCmd
    adb shell < .adbShellCmd
    adb shell am force-stop $APPNAME

    #Kill GDB server
    echo "Stop gdb server"
    GDBSERVER_PID=$(adb shell ps | grep gdbserver | awk {'print $2'})
    echo "run-as $APPNAME" > .adbShellCmd
    echo "kill -s SIGQUIT $GDBSERVER_PID" >> .adbShellCmd
    adb shell < .adbShellCmd

    #Kill log monitor
    echo "Stop log monitor"
    LOGMONITOR_PID=$(adb shell ps | grep logMonitor | awk {'print $2'})
    echo "run-as $APPNAME" > .adbShellCmd
    echo "kill -s SIGQUIT $LOGMONITOR_PID" >> .adbShellCmd
    adb shell < .adbShellCmd
;;

log)
    echo "run-as $APPNAME" > .adbShellCmd
    echo "./logMonitor" >> .adbShellCmd
    $CONSOLE --hold -e bash -c 'adb shell < .adbShellCmd' &
;;
esac


