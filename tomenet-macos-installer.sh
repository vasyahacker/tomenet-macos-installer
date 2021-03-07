#!/bin/sh

# TARGET_DIR='./TomeNET.app'
TARGET_DIR=~/Desktop/TomeNET.app
TOMENET_URL='https://tomenet.eu/downloads/TomeNET-473-client-OSX-amd64-withsfx.tar.bz2'
FONTS_URL='https://drive.google.com/uc?export=download&id=1CCnHi_BABM_n7ybYL_eiABOyd-kEL_xp'
ICON_URL='https://tomenet.eu/downloads/tomenet4.png'
# FONT_URL='http://tangar.info/wp-content/uploads/2016/03/16x24t.pcf'
INFO_PLIST='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>CFBundleExecutable</key>
		<string>run.sh</string>
		<key>CFBundleIconFile</key>
		<string>icon.icns</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>4.7.3</string>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleSignature</key>
		<string></string>
		<key>CFBundleVersion</key>
		<string>4.7.3</string>
	</dict>
</plist>'

RUN_SH='#!/bin/sh

MAIN_FONT="16x22tg"
SMALLER_FONT="8x13"
xset fp+ ~/.fonts
xset fp rehash

export TOMENET_X11_FONT=${MAIN_FONT}
export TOMENET_X11_FONT_MIRROR=${SMALLER_FONT}
export TOMENET_X11_FONT_RECALL=${SMALLER_FONT}
export TOMENET_X11_FONT_CHOICE=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_4=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_5=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_6=${SMALLER_FONT}
export TOMENET_X11_FONT_TERM_7=${SMALLER_FONT}
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
cd $DIR
export DYLD_LIBRARY_PATH=.
./tomenet -p18348 -m europe.tomenet.eu &
'

download(){
	local url=$1
	local to=$2
	curl -s $url -L --output $to
}

fail(){
 echo "ERROR: $1"
 exit 1
}
RED=$(printf "\033[31m")
GREEN=$(printf "\033[32m")
BGBLUE=$(printf "\033[44m\033[1m")
NORMAL=$(printf "\033[0m")
startwait()
{
  tput civis
  sp='/-\|'
  printf "$1"
  while :;do 
      temp=${sp#?}
      printf "[%c]" "$sp" 
      sp=$temp${sp%"$temp"}
      printf "\b\b\b"
    sleep 0.05
  done &
  trap "kill $!" EXIT
}
endwait(){
 tput cnorm
 kill $! 
 wait $! 2>/dev/null 
 trap " " EXIT 
 printf " [ ${GREEN}$1${NORMAL} ]\n"
}
DONE="Done"
startwait "Downloading TomeNET 4.7.3 for MacOS..."
mkdir -p $TARGET_DIR
cd $TARGET_DIR
mkdir -p {Contents/MacOS,Contents/Resources}
download $TOMENET_URL tn.tar.bz2 && tar xjf tn.tar.bz2 || DONE="Error"
rm -f tn.tar.bz2
mv ./TomeNET/* ./Contents/MacOS/
chmod +x ./Contents/MacOS/tomenet
rm -rf ./TomeNET
endwait $DONE
DONE="Done"
startwait "Installing Tangar's fonts..."
download $FONTS_URL fonts.zip && unzip -q fonts.zip || DONE="Error"
rm -f fonts.zip

mkdir -p ~/.fonts

cp ./pcf/* ~/.fonts/
rm -rf ./pcf

cp ./prf/* ./Contents/MacOS/lib/user/
rm -rf ./prf
endwait $DONE
DONE="Done"
#for i in `find . -name "font-custom-*"`; do mv "$i" "$(printf "$i"|tr "[:upper:]" "[:lower:]")";done
startwait "Make TomeNET original icon for MacOS app..."
download $ICON_URL icon.png || DONE="Error"
sips -Z 1024 icon.png > /dev/null || DONE="Error"
mkdir icon.iconset
sips -z 16 16     icon.png --out icon.iconset/icon_16x16.png > /dev/null || DONE="Error"
sips -z 32 32     icon.png --out icon.iconset/icon_16x16@2x.png > /dev/null
sips -z 32 32     icon.png --out icon.iconset/icon_32x32.png > /dev/null
sips -z 64 64     icon.png --out icon.iconset/icon_32x32@2x.png > /dev/null
sips -z 128 128   icon.png --out icon.iconset/icon_128x128.png > /dev/null
sips -z 256 256   icon.png --out icon.iconset/icon_128x128@2x.png > /dev/null
sips -z 256 256   icon.png --out icon.iconset/icon_256x256.png > /dev/null
sips -z 512 512   icon.png --out icon.iconset/icon_256x256@2x.png > /dev/null
sips -z 512 512   icon.png --out icon.iconset/icon_512x512.png > /dev/null
mv icon.png icon.iconset/icon_512x512@2x.png > /dev/null
iconutil -c icns icon.iconset > /dev/null
rm -R icon.iconset
mv icon.icns ./Contents/Resources
endwait $DONE

printf "$RUN_SH" > ./Contents/MacOS/run.sh
chmod +x ./Contents/MacOS/run.sh
printf "$INFO_PLIST" > ./Contents/Info.plist
echo "Now you can run $TARGET_DIR (XQuartz is required)"
