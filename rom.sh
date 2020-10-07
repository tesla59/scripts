#!/bin/bash
 # Copyright (c) 2020 Tesla59 <talktonishantsingh.ns@gmail.com>

# Configs
ROM=$1
DEVICE=$2
VARIANT=$3
gapps=1
ID=""
token=""

##################################################################################################


if [ -z ${1} ] || [ -z ${2} ] || [ -z ${3} ]
then
    echo -e "Usage: bash rom.sh <rom-name> <device-name> <variant> "
fi

shopt -s nocaseglob
# GApps
if [ $gapps = 1 ]
then
	export BUILD_WITH_GAPPS=true
else
	export BUILD_WITH_GAPPS=false
fi


function post_msg {
        curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" -d chat_id="$1" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$2"
}

function post_doc {
	curl --progress-bar -F document=@"$2" "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$1"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"
}

function pin_message {
        curl -s -X POST "https://api.telegram.org/bot$token/pinChatMessage" \
        -d chat_id="$1" \
        -d message_id="$2"
}

ccache -M 50G
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

function build {
	rm out/target/product/"$DEVICE"/*official*.zip
	post_msg "$ID" "<code>Build Started</code>"
	BUILD_START=$(date +"%s")
	. build/envsetup.sh
	lunch "$ROM"_"$DEVICE"-$VARIANT
	mka bacon | tee log
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
}

function upload {
	post_msg "$ID" "<code>Build Completed in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)</code>"
	cd out/target/product/$DEVICE
	file=$(ls *official*.zip)
	datecode=$(date +%Y%m%d)
        rclone copy $file tesla:android/$DEVICE/$ROM/$datecode/
        LINK="https://downloads.tesla59.workers.dev/$DEVICE/$ROM/$datecode/$file"
        pinid=$(post_msg "$ID" "$LINK" | jq .result.message_id)
	pin_message "$ID" "$pinid"
}

function error {
	cat log | grep -i failed -A5 > error.log
        post_doc "$ID" "error.log" "Build Failed After $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
        post_msg "$ID" "@tesla59  FEEX EET ASAAAP"
}

##################################################################################################

build
if [ -f out/target/product/$DEVICE/*official*.zip ]
then
	upload
else
	error
fi
