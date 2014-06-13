#!/bin/bash

echo Initializing GIT...
git init
git add .
echo Adding AppMaker submodule
git submodule add git@github.com:guenterapps/AppMaker.git
git submodule init
git submodule update
echo Initializng AppMaker submodules
cd AppMaker
git submodule init
git submodule update
echo Finished!


