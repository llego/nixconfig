#!/usr/bin/env bash

# Set variables
ALBUM_DOWNLOADER_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/album-downloader"
CACHE="$ALBUM_DOWNLOADER_HOME/bandcamp-collection-downloader.cache"
# Cookie is managed by agenix and decrypted at /run/agenix/bandcamp-cookie
COOKIE="/run/agenix/bandcamp-cookie"

BANDCAMP_MUSIC_PATH="${XDG_MUSIC_DIR:-$HOME/Music}/bandcamp"
# Crisuflix tailscale IP from networking variables (100.123.67.48)
REMOTE_HOST="llego@100.123.67.48"
REMOTE_HOST_PATH="$REMOTE_HOST:/mnt/illby/transient/beets-import"

# Central cache server settings (VPS tailscale IP: 100.78.37.16)
CENTRAL_CACHE_HOST="llego@100.78.37.16"
CENTRAL_CACHE_PATH="/opt/album-downloader"
CENTRAL_CACHE_FILE="$CENTRAL_CACHE_HOST:$CENTRAL_CACHE_PATH/bandcamp-collection-downloader.cache"

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
    echo -e "${CYAN}3)${RESET} Sync cache to central server"
    echo -e "${CYAN}q)${RESET} Quit"
    echo -e "${BOLD}${BLUE}======================================${RESET}"
}

# Create config dir if it does not exist
mkdir -p "$ALBUM_DOWNLOADER_HOME" || exit 1

# Function to sync cache from central server
sync_cache_from_remote() {
    echo -e "${CYAN}Syncing cache from central server...${RESET}"
    if ssh -o ConnectTimeout=10 "$CENTRAL_CACHE_HOST" "test -f $CENTRAL_CACHE_PATH/bandcamp-collection-downloader.cache"; then
        rsync -e "ssh -o ConnectTimeout=10" "$CENTRAL_CACHE_FILE" "$ALBUM_DOWNLOADER_HOME/"
        echo -e "${GREEN}✔ Cache synced from central server${RESET}"
    else
        echo -e "${YELLOW}⚠ No cache found on central server (may be first run)${RESET}"
    fi
}

# Function to sync cache to central server
sync_cache_to_remote() {
    echo -e "${CYAN}Syncing cache to central server...${RESET}"
    if rsync -e "ssh -o ConnectTimeout=10" "$CACHE" "$CENTRAL_CACHE_FILE"; then
        echo -e "${GREEN}✔ Cache synced to central server${RESET}"
    else
        echo -e "${YELLOW}⚠ Failed to sync cache to central server (server may be offline)${RESET}"
    fi
}

# Main loop
while true; do
    print_menu
    echo
    read -r -p "$(printf '%b' "${YELLOW}Enter your choice: ${RESET}")" choice
    echo

    case $choice in
        1)
            echo -e "${GREEN}✔ Downloading new bandcamp albums${RESET}"
            
            # Sync cache from central server before downloading
            sync_cache_from_remote
               
            # Create music folder if it does not exist
            if [ ! -d "$BANDCAMP_MUSIC_PATH" ]; then
                echo -e "Directory does not exist. Creating directory \n " "$BANDCAMP_MUSIC_PATH"
                mkdir -p "$BANDCAMP_MUSIC_PATH"
            fi
            
            # Copy cache to music folder for bandcamp-collection-downloader
            if [ -f "$CACHE" ]; then
                cp "$CACHE" "$BANDCAMP_MUSIC_PATH/"
            fi
            
            bandcamp-collection-downloader -f flac -d "$BANDCAMP_MUSIC_PATH" -c "$COOKIE" llego202

            echo -e "\n${YELLOW}Note: Remember to sync cache to central server (option 3) when ready${RESET}"
            ;;
        2)
            echo -e "${GREEN}✔ Rsyncing bandcamp albums to the server \n From: $BANDCAMP_MUSIC_PATH/ \n To: $REMOTE_HOST_PATH${RESET}"
            eval rsync -r --info=progress2 "$BANDCAMP_MUSIC_PATH"/ "$REMOTE_HOST_PATH"
            ;;
        3)
            echo -e "${GREEN}✔ Syncing cache to central server${RESET}"
            sync_cache_to_remote
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
