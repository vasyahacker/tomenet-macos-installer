#!/bin/sh

echo "TomeNET build script (for macos)"

type brew &>/dev/null || {
  echo 'Install brew please'
  open 'https://brew.sh'
  exit 1
}
echo "The libraries will be installed now: sdl_mixer sdl_sound libgcrypt\n[press enter to continue or ctrl-c to exit]"
read
brew install sdl_mixer sdl_sound libgcrypt
echo "Downloading TomeNET sources..."
curl -s https://www.tomenet.eu/downloads/tomenet-4.7.4a.tar.bz2 -L --output tomenet.tar.bz2
echo "Unpacking..."
tar xjf tomenet.tar.bz2
#git clone https://github.com/TomenetGame/tomenet.git
echo "Make sure that the XQuartz is already installed"
echo "Building..."
cd 'tomenet-4.7.4a/src'
make -f makefile.osx
make install
echo "Done"

