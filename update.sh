#!/bin/bash

# get latest version from github
LATEST_TAG=$(curl -s https://raw.githubusercontent.com/julianoberhaensli/teamspeak5-egg/master/tstag)
LATEST_VERSION=$(curl -s https://raw.githubusercontent.com/julianoberhaensli/teamspeak5-egg/master/tsversion)
echo "Latest TeamSpeak Version: $LATEST_TAG"

# get installed version from version_installed.txt
INSTALLED_TAG=$(cat version_installed.txt)
echo "Installed TeamSpeak Version: $INSTALLED_TAG"

# check if there is a static version set in pterodactyl panel
. "tag_static.txt"
STATIC_VERSION=0
if ! [ "$SERVER_TAG" = "undefined" ] && ! [ "$SERVER_TAG" = 0 ];
then
    STATIC_VERSION=1
    echo "Server is set to static tag: $SERVER_TAG and version: $SERVER_VERSION" 
fi

updateToVersion() {
    TSTAG=$1
    TSVERSION=$2
    echo "cleaning up files before the update..."
    rm -r doc
    rm -r redist
    rm -r serverquerydocs
    rm -r sql
    rm -r tsdns
    rm -r CHANGELOG
    rm ./*.so
    rm ./LICENSE*
    rm tsserver
    echo "downloading teamspeak version $TSVERSION and extracting file..."
    curl -s -L https://github.com/TeamSpeak-Systems/ts-native/releases/download/beta-58rc20/teamspeak-server_linux_amd64-v5.0.0-beta14-rc16.tar.bz2 | tar jxf - --strip-components=1
    echo 'download and extraction finished'
    chmod +x tsserver_minimal_runscript.sh
    echo 'permissions set.'
    echo '' > .tsserver_license_accepted
    echo 'accepted license'
    echo "$TSTAG" > tag_installed.txt
    echo "$TSVERSION" > version_installed.txt
    echo 'version written into version_installed.txt file'
}

if [ "$LATEST_TAG" != "$INSTALLED_TAG" ] && [ "$STATIC_VERSION" = 0 ];
then
    updateToVersion "$LATEST_TAG" "$LATEST_VERSION"
elif [ "$SERVER_TAG" != "$INSTALLED_TAG" ] && [ "$STATIC_VERSION" = 1 ];
then
    updateToVersion "$SERVER_TAG" "$SERVER_VERSION"
else
    echo 'No update required.'
fi

if [ ! -f tsserver.ini ]; then
    ./tsserver_startscript.sh start createinifile=1
    PID=$(pgrep ts3server)
    kill "$PID"
fi

echo 'starting server...'
./tsserver_minimal_runscript.sh inifile=tsserver.ini
