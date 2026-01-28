#!/usr/bin/env bash

# Set variables
ALBUM_DOWNLOADER_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/album-downloader"
CACHE="$ALBUM_DOWNLOADER_HOME/bandcamp-collection-downloader.cache"
COOKIE="$ALBUM_DOWNLOADER_HOME/bandcamp.com_cookies.txt"

BANDCAMP_MUSIC_PATH="${XDG_MUSIC_DIR:-$HOME/Music}/bandcamp"
REMOTE_HOST="llego@truenas.home"
REMOTE_HOST_PATH="$REMOTE_HOST:/mnt/illby/transient/beets-import"

# Color definitions
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

# Function to display menu
print_menu() {
    echo -e "${BOLD}${BLUE}========== Album Downloader ==========${RESET}"
    echo -e "${CYAN}1)${RESET} Download bandcamp collection"
    echo -e "${CYAN}2)${RESET} Rsync bandcamp albums to truenas"
    echo -e "${CYAN}q)${RESET} Quit"
    echo -e "${BOLD}${BLUE}======================================${RESET}"
}

# Create config dir if it does not exist
mkdir -p "$ALBUM_DOWNLOADER_HOME" || exit 1

# Main loop
while true; do
    print_menu
    echo
    read -r -p "$(printf '%b' "${YELLOW}Enter your choice: ${RESET}")" choice
    echo

    case $choice in
        1)
            echo -e "${GREEN}✔ Downloading new bandcamp albums${RESET}"
              
            # Create music folder if it does not exist
            if [ ! -d "$BANDCAMP_MUSIC_PATH" ]; then
                echo -e "Directory does not exist. Creating directory \n " "$BANDCAMP_MUSIC_PATH" " and copying over cache file"
                mkdir -p "$BANDCAMP_MUSIC_PATH"
                cp "$CACHE" "$BANDCAMP_MUSIC_PATH"
            fi
            
            bandcamp-collection-downloader -f flac -d "$BANDCAMP_MUSIC_PATH" -c "$COOKIE" llego202

            # Need to ensure that cache file is updated in .config/album-downloader!
            echo -e "\nBacking up cache file to .config \n"
            rsync "$CACHE" "$ALBUM_DOWNLOADER_HOME/"
            ;;
        2)
            echo -e "${GREEN}✔ Rsyncing bandcamp albums to the server \n From: $BANDCAMP_MUSIC_PATH/ \n To: $REMOTE_HOST_PATH${RESET}"
            eval rsync -r --info=progress2 "$BANDCAMP_MUSIC_PATH"/ "$REMOTE_HOST_PATH"
            ;;
        q|Q)
            echo -e "${BOLD}${RED}✖ Exiting. Goodbye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}⚠ Invalid option.${RESET}"
            ;;
    esac

    # echo
    # read -r -p "$(printf '%b' "${YELLOW}Enter your choice: ${RESET}")" choice
    clear
done
