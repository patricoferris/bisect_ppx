#!/usr/bin/env bash

esy_build() {
    set -e
    set -x
    esy install
    esy build
    esy dune build -p bisect_ppx src/ppx/bucklescript/ppx.exe
    cp _build/default/src/ppx/bucklescript/ppx.exe ./ppx
    cp _build/install/default/bin/bisect-ppx-report ./bisect-ppx-report
    exit 0
}

UNAME=`uname -s`
RESULT=$?
if [ "$RESULT" != 0 ]
then
    echo "Cannot detect OS; falling back to a source build."
    esy_build
fi

case "$UNAME" in
    "Linux") OS=linux;;
    "Darwin") OS=macos;;
    *) echo "Unknown OS '$UNAME'; falling back to a source build."; esy_build;;
esac

if [ ! -f bin/$OS/ppx ]
then
    echo "bin/$OS/ppx not found; falling back to a source build."
    esy_build
fi

if [ ! -f bin/$OS/bisect-ppx-report ]
then
    echo "bin/$OS/bisect-ppx-report not found; falling back to a source build."
    esy_build
fi

bin/$OS/bisect-ppx-report --version > /dev/null
RESULT=$?
if [ "$RESULT" != 0 ]
then
    echo "Pre-built binaries invalid; falling back to a source build."
    esy_build
fi

cp bin/$OS/ppx ./ppx
cp bin/$OS/bisect-ppx-report ./bisect-ppx-report
