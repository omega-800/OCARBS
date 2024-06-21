#!/usr/bin/env bash

git clone https://github.com/omega-800/dwm.git
cd dwm && sudo make install && cd ..
git clone https://github.com/omega-800/st.git
cd st && sudo make install && cd ..
git clone https://github.com/omega-800/slock.git
cd slock && sudo make install && cd ..
sudo pacman --noconfirm -S  xorg-{xset{,root},xinit,server} xf86-video-intel nvidia 
