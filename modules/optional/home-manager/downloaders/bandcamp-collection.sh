#!/bin/bash

# Set variables
BANDCAMP_HOME="${XDG_DATA_HOME:-${HOME}/nixconfig/modules/optional/home-manager/downloaders}"
#BANDCAMP_HOME="${XDG_DATA_HOME:-${HOME}/bandcamp-collection}";

CACHE="$BANDCAMP_HOME/bandcamp-collection-downloader.cache"
COOKIE="$BANDCAMP_HOME/bandcamp.com_cookies.txt"

BANDCAMP_MUSIC_PATH="${XDG_DATA_HOME:-${HOME}/Music/bandcamp}"
TIDAL_MUSIC_PATH="${XDG_DATA_HOME:-${HOME}/Music/tidal}"

REMOTE_HOST="llego@truenas.home"
REMOTE_HOST_PATH="$REMOTE_HOST:/mnt/illby/transient/beets-import"


# Download bandcamp collection
echo -e "\nDownload new bandcamp albums? \n"
read -p "[y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  
  # Create music folder if it does not exist
  if [ ! -d "$BANDCAMP_MUSIC_PATH" ]; then
     echo -e "Directory does not exist. Creating directory \n " "$BANDCAMP_MUSIC_PATH" " and copying over cache file"
     mkdir -p "$BANDCAMP_MUSIC_PATH"
     cp "$CACHE" "$BANDCAMP_MUSIC_PATH"
  fi

  echo -e "\nDownloading new albums from bandcamp \n" 
  
  #nix run github:ovyerus/bandsnatch -- run --format flac --output-folder "$BANDCAMP_MUSIC_PATH" --cookies "$COOKIE" llego202
  bandsnatch run --format flac --output-folder "$BANDCAMP_MUSIC_PATH" --cookies "$COOKIE" llego202
  
  echo -e "\nBacking up cache file \n"
  rsync "$BANDCAMP_MUSIC_PATH/bandcamp-collection-downloader.cache" "$BANDCAMP_HOME/"
fi


# Rsync bandcamp albums to truenas
echo -e "\nRsync bandcamp albums to the server? \n From: $BANDCAMP_MUSIC_PATH/ \n To: $REMOTE_HOST_PATH \n" 
read -p "[y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo -e "\nRsyncing bandcamp albums to server \n"
  eval rsync -r --info=progress2 "$BANDCAMP_MUSIC_PATH"/ "$REMOTE_HOST_PATH"
fi


# Rsync tidal albums to truenas
echo -e "\nRsync tidal albums to the server? \n From: $TIDAL_MUSIC_PATH/ \n To: $REMOTE_HOST_PATH \n" 
read -p "[y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo -e "\nRsyncing tidal albums to server \n"
  eval rsync -r --info=progress2 "$TIDAL_MUSIC_PATH"/ "$REMOTE_HOST_PATH"
fi



# Run beets on remote host
echo -e "\nConnect to beets container on remote host and run 'beet import /import'?\n" 
read -p "[y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo -e "\nConnecting to docker container on remote host and running 'beet import /import' \n"
  DOCKER_HOST=tcp://$REMOTE_HOST sudo docker exec -it beets bash -c 'beet import /import'
fi

