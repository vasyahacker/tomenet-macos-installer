# TomeNET MacOS installer

Build [TomeNET](https://tomenet.eu) native application for MacOS 

### Requirements
[XQuartz](https://www.xquartz.org), SDL_mixer and more - no matter, **the script will take care of everything**

### Install
Just run in terminal:
```
/bin/bash -c "$(curl -fsSL https://github.com/vasyahacker/tomenet-macos-installer/raw/main/tomenet-macos-installer.sh)"
```
Then follow the instructions and TomeNET.app will appear on your desktop

### Screenshots

![icon, version, size](https://github.com/vasyahacker/tomenet-macos-installer/raw/main/scrn/scr.png "main window")

### Tested
- MacOS 13.1 Intel
- MacOS 13.1 M1
- MacOS 13.1 M1 Max

If you get a message: "The application "TomeNET" cannot be opened." try:
```bash
sudo xattr -r -d com.apple.quarantine /path/to/TomeNET.app
```
