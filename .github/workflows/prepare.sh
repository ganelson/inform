#!/bin/sh

set -e

ROOT=$PWD
cd ..

echo "Downloading Inweb"
rm -rf inweb
curl -Ls https://github.com/ganelson/inweb/archive/refs/heads/master.tar.gz | tar xz
mv inweb-master inweb -f
echo "Compiling Inweb"
bash inweb/scripts/first.sh linux

echo "Downloading Intest"
rm -rf intest
curl -Ls https://github.com/ganelson/intest/archive/refs/heads/master.tar.gz | tar xz
mv intest-master intest -f
echo "Compiling Intest"
bash intest/scripts/first.sh

cd $ROOT