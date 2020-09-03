#!/bin/bash
 # Copyright (c) 2020 Tesla59 <talktonishantsingh.ns@gmail.com>

#Configs
ID=""
token=""
MAKECLEAN=1
MAKEDTBO=1


############################################################################################################################

MSG_URL="https://api.telegram.org/bot$token/sendMessage"
BUILD_URL="https://api.telegram.org/bot$token/sendDocument"
post_msg() {
        curl -s -X POST "$MSG_URL" -d chat_id="$ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$1"
}
post_doc() {
        curl --progress-bar -F document=@"$1" "$BUILD_URL" \
        -F chat_id="$ID"  \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$2"
}

clone_tc()  {
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 --depth=1 gcc
	git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 --depth=1 gcc32
	git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 clang
	git clone https://android.googlesource.com/platform/system/libufdt scripts/ufdt/libufdt
}

makeclean() {
	make O=out clean
	make O=out mrproper
	rm -rf out zipper
	mkdir out
}
compile() {
	post_msg "<code>Compilation started for StromBreaker Kernel</code>"
	BUILD_START=$(date +"%s")
	make O=out ARCH=arm64 vendor/violet-perf_defconfig
	make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang/clang-r370808/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-linux-androideabi-" | tee full.log
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
}

makedtbo() {
	python2 "scripts/ufdt/libufdt/utils/src/mkdtboimg.py" \
	create "out/arch/arm64/boot/dtbo.img" --page_size=4096 "out/arch/arm64/boot/dts/xiaomi/violet-sm6150-overlay.dtbo"
	cp out/arch/arm64/boot/dtbo.img zipper
}

error() {
	post_doc "full.log" "Build failed after $(($DIFF / 60)) mins and $(($DIFF % 60)) Second(s)"
}

zip() {
	file="stormbreaker-$(TZ=Asia/Kolkata date +'%Y%m%d-%H%M')-dtbo.zip"
	cp out/arch/arm64/boot/Image.gz-dtb zipper
	cd zipper
	zip -r9 $file * -x README.md $file
	post_doc "$file" "Build Completed in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
}

################################################################################################################

clone_tc > /dev/null

if [ $MAKECLEAN = 1 ]
then
	makeclean
fi

compile

if [ $MAKEDTBO = 1 ]
then
	makedtbo
fi

if [ -f out/arch/arm64/boot/Image.gz-dtb ]
then
	zip
else
	error
fi
