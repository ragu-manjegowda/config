#!/bin/bash

if [ ${PWD##*/} != cpptools ]; then
  	echo "Wrong directory"
    exit -1
fi

find ./ -mindepth 1 -name update.sh -prune -o -exec rm -rf {} +

function download_cpptools {
    url=https://github.com/microsoft/vscode-cpptools/releases/latest/download/cpptools-$1.vsix
    echo $url
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    os="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    os="osx"
fi

curl -L -O $(download_cpptools $os)

unzip cpptools-*.vsix

if [ -f extension/debugAdapters/*/OpenDebugAD7 ]; then
    chmod 755 extension/debugAdapters/*/OpenDebugAD7
fi

cp extension/cppdbg.ad7Engine.json extension/debugAdapters/bin/nvim-dap.ad7Engine.json

