#!/bin/bash
# shellcheck disable=SC2166
VERSION='4.9.0'

TARGET_DIR=~/Desktop/TomeNET.app
RELEASE="tomenet-$VERSION"
LIBS_REQUIRED='libvorbis libogg sdl2 sdl2_mixer sdl2_sound' # libmikmod libgcrypt
TOMENET_URL="https://www.tomenet.eu/downloads/$RELEASE.tar.bz2"
ICON_URL='https://tomenet.eu/downloads/tomenet4.png'

FONTS_URL='https://drive.google.com/uc?export=download&id=1CCnHi_BABM_n7ybYL_eiABOyd-kEL_xp'
ARCH=$(arch)

RED=$(printf "\033[31m")
GREEN=$(printf "\033[32m")
NORMAL=$(printf "\033[0m")

INFO_PLIST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
	<dict>
		<key>CFBundleExecutable</key>
		<string>run.sh</string>
		<key>CFBundleIconFile</key>
		<string>icon.icns</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>$VERSION</string>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleSignature</key>
		<string></string>
		<key>CFBundleVersion</key>
		<string>$VERSION</string>
	</dict>
</plist>"

RUN_SH='#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
	DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

[ -e ~/.tomenetrc ] || cp "$DIR/.tomenetrc" ~/

osascript -e "display dialog \"Select TomeNET main window font:\" buttons {\"Default font\", \"Tangars font\"} \
default button \"Tangars font\" cancel button \"Default font\""  > /dev/null 2>&1 && {
  /opt/X11/bin/xset fp+ "$DIR/fonts"
  /opt/X11/bin/xset fp rehash
  sed -i -e "s/^Mainwindow_Font.*$/Mainwindow_Font 16x22tg/" ~/.tomenetrc
  true
} || {
  sed -i -e "s/^Mainwindow_Font.*tg$/Mainwindow_Font 8x13/" ~/.tomenetrc
}

cd $DIR
_arch="$(arch)"
export DYLD_LIBRARY_PATH="./$_arch"
./tomenet-$_arch &
'

download(){
	_url=$1
	_to=$2
	curl -s "$_url" -L --output "$_to"
}

fail() {
 echo "ERROR: $1"
 exit 1
}

read_char() {
  stty -icanon -echo
  eval "$1=\$(dd bs=1 count=1 2>/dev/null)"
  stty icanon echo
}

Yn() {
  _prompt="$1"
  _ans=""
  printf "%s [Y/n]: " "$_prompt"
  while IFS= read_char _ans
  do
    [ "$_ans" = "n" -o "$_ans" = "N" ] && { printf "%sN%s\n" "${RED}" "${NORMAL}"; return 1; }
    [ "$_ans" = "" -o "$_ans" = "y" -o "$_ans" = "Y" ] && { printf "%sY%s\n" "${GREEN}" "${NORMAL}"; return 0; }
  done
}

startwait() {
  tput civis
  sp='/-\|'
  printf "%s" "$1"
  while :;do 
      temp=${sp#?}
      printf "[%c]" "$sp" 
      sp=$temp${sp%"$temp"}
      printf "\b\b\b"
    sleep 0.05
  done &
  trap 'kill $!' EXIT
}

endwait() {
 tput cnorm
 kill $! 
 wait $! 2>/dev/null 
 trap " " EXIT 
 printf " [ %s%s%s ]\n" "${GREEN}" "$1" "${NORMAL}"
}

mfget() {
  _url="$1"
  _to="$2"
  _direct_url="$(curl -s "$_url" | grep -o 'download[0-9]*\.mediafire.com[^"]\+' | tail -1)"
  [ -z "$_direct_url" ] && return 1
  curl "$_direct_url" -L --output "$_to" || return 1
  return 0
}

check_req_pkg() {
	_pkg="$1"
	_cmd="$2"
	type "$_cmd" >/dev/null || {
	  echo "$_pkg not installed"
	  Yn "Install $_pkg?" && {
	  	brew install "$_pkg"
	  	return 0
	  } || return 1
	}
	return 0
}

mkdir -p $TARGET_DIR
cd $TARGET_DIR || fail "can't 'cd $TARGET_DIR'"

type brew &>/dev/null || {
  echo 'Homebrew not installed'
  Yn "Install brew?" || fail "Can't continue without homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

echo "The libraries will be installed now: $LIBS_REQUIRED"
# shellcheck disable=SC2086
Yn "Run brew install $LIBS_REQUIRED" && brew install $LIBS_REQUIRED

#check_req_pkg "git" "git"  || fail "git is required!"
check_req_pkg xquartz Xquartz || fail "Xquartz is required!"

echo "Downloading TomeNET sources..."
download $TOMENET_URL tomenet.tar.bz2
echo "Unpacking..."
tar xjf tomenet.tar.bz2
rm -f tomenet.tar.bz2
# git clone https://github.com/TomenetGame/tomenet.git
echo "Building..."
cd "$RELEASE/src" || fail "can't '$RELEASE/src'"
sed -i -e 's/sdl-config/sdl2-config/g' makefile.osx
sed -i -e 's/-lSDL\_mixer/-lSDL2\_mixer/g' makefile.osx
make -f makefile.osx tomenet || fail "build error"
echo "Buid complete!"
cd $TARGET_DIR || fail "can't 'cd $TARGET_DIR'"
mkdir -p {Contents/MacOS,Contents/Resources}
mv $RELEASE/{lib,TomeNET-Guide*,.tomenetrc,tomenet.ini.default} ./Contents/MacOS/
mv $RELEASE/src/tomenet "./Contents/MacOS/tomenet-$ARCH"
strip "./Contents/MacOS/tomenet-$ARCH"
rm -rf $RELEASE

echo "Copying libs to app folder..."
mkdir -p "$TARGET_DIR/Contents/MacOS/$ARCH"
for _lib in $LIBS_REQUIRED; do
	_libs="$(brew --prefix "$_lib")/lib/*.dylib"
	# shellcheck disable=SC2086
	cp -v $_libs "$TARGET_DIR/Contents/MacOS/$ARCH"
done

for _lib in $LIBS_REQUIRED; do
	Yn "brew remove $_lib" && brew remove "$_lib"
done

Yn "Install sound?" && check_req_pkg "7zip" "7zz" && {
	echo "Downloading sound pack.."
	mfget "http://www.mediafire.com/?issv5sdv7kv3odq" sound.7z || DONE="failed"
	#mfget "http://www.mediafire.com/?eqx5m1mk553y6ow" sound.7z || DONE="failed" #tangar
	DONE="Done"
	startwait "Installing sound pack..."
		7zz x sound.7z &>/dev/null || DONE="failed"
		rm -f sound.7z
		mv -f sound/* ./Contents/MacOS/lib/xtra/sound/
		rm -rf sound
	endwait $DONE
}

Yn "Install music?" && check_req_pkg "7zip" "7zz" && {
	echo "Downloading music pack.."
	mfget "http://www.mediafire.com/?3j87kp3fgzpqrqn" music.7z || DONE="failed"
	DONE="Done"
	#mfget "http://www.mediafire.com/?nu09e6a5i4fo0gf" music.7z || DONE="failed" #tangar
	startwait "Installing music pack..."
		7zz x -ptomenet music.7z &>/dev/null || DONE="failed"
		rm -f music.7z
		mv -f music/* ./Contents/MacOS/lib/xtra/music/
		rm -rf music
	endwait $DONE
}

Yn "brew remove 7zip" && brew remove 7zip
# Yn "brew remove git" && brew remove git

# Yn "Install Tnagra's fonts" && {
	echo "Turning off font_map_solid_walls.."
	sed -i '' 's/Y:font_map_solid_walls/X:font_map_solid_walls/' ./Contents/MacOS/lib/user/options.prf

	DONE="Done"
	startwait "Installing Tangar's fonts..."
		_fdir="./Contents/MacOS/fonts"
		download "$FONTS_URL" fonts.zip && unzip -q fonts.zip || DONE="Error"
		rm -f fonts.zip
		mkdir -p $_fdir
		cp ./pcf/* $_fdir
		(cd $_fdir &&	/opt/X11/bin/mkfontdir)
		rm -rf ./pcf
		cp ./prf/* ./Contents/MacOS/lib/user/
		rm -rf ./prf
	endwait $DONE
# }

DONE="Done"
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

printf "%s" "$RUN_SH" > ./Contents/MacOS/run.sh
chmod +x ./Contents/MacOS/run.sh
printf "%s" "$INFO_PLIST" > ./Contents/Info.plist

echo "Complete!"
echo "Now you can open $TARGET_DIR (XQuartz is required)"
Yn "Open $TARGET_DIR now?" && open $TARGET_DIR

exit 0
