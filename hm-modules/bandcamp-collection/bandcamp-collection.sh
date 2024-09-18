#!/bin/bash

# Set variables
BANDCAMP_HOME="${XDG_DATA_HOME:-${HOME}/nixos/hm-modules/bandcamp-collection}"
CACHE="$BANDCAMP_HOME/bandcamp-collection-downloader.cache"

COOKIE="$BANDCAMP_HOME/bandcamp.com_cookies.txt"

MUSIC_PATH="${XDG_DATA_HOME:-${HOME}/Music/bandcamp}"

REMOTE_HOST="llego@docker.home"
REMOTE_HOST_PATH="$REMOTE_HOST:/mnt/beets-import"


# Download bandcamp collection
echo -e "\nDownload new bandcamp albums? \n"
read -p "[y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  
  # Create music folder if it does not exist
  if [ ! -d "$MUSIC_PATH" ]; then
     echo -e "Directory does not exist. Creating directory \n " "$MUSIC_PATH" " and copying over cache file"
     mkdir -p "$MUSIC_PATH"
     cp "$CACHE" "$MUSIC_PATH"
  fi

  echo -e "\nDownloading new albums from bandcamp \n" 
  
  #nix run github:ovyerus/bandsnatch -- run --format flac --output-folder "$MUSIC_PATH" --cookies "$COOKIE" llego202
  bandsnatch run --format flac --output-folder "$MUSIC_PATH" --cookies "$COOKIE" llego202
  
  echo -e "\nBacking up cache file \n"
  rsync "$MUSIC_PATH/bandcamp-collection-downloader.cache" "$BANDCAMP_HOME/"
fi


# Rsync music to truenas
echo -e "\nRsync music to the server? \n From: $MUSIC_PATH/ \n To: $REMOTE_HOST_PATH \n" 
read -p "[y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo -e "\nRsyncing to server \n"
  eval rsync -r --info=progress2 "$MUSIC_PATH"/ "$REMOTE_HOST_PATH"
fi



# Run beets on remote host
echo -e "\nConnect to beets container on remote host? \n Command to run: $DOCKER_COMMAND \n" 
read -p "[y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo -e "\nConnecting to docker container on remote host \n"
  DOCKER_HOST=tcp://$REMOTE_HOST docker exec -it beets bash -c 'beet import /import'
fi

