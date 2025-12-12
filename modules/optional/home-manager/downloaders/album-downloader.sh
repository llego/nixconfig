#!bash

# Set variables
BANDCAMP_HOME="${HOME}/nixconfig/modules/optional/home-manager/downloaders"
#BANDCAMP_HOME="${XDG_DATA_HOME:-${HOME}/bandcamp-collection}";

CACHE="$BANDCAMP_HOME/bandcamp-collection-downloader.cache"
COOKIE="$BANDCAMP_HOME/bandcamp.com_cookies.txt"

BANDCAMP_MUSIC_PATH="${HOME}/Music/bandcamp"
TIDAL_MUSIC_PATH="${HOME}/Music/tidal"

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
    echo -e "${CYAN}3)${RESET} Rsync tidal albums to truenas"
    echo -e "${CYAN}4)${RESET} Run beets on remote host"
    echo -e "${CYAN}q)${RESET} Quit"
    echo -e "${BOLD}${BLUE}======================================${RESET}"
}

# Main loop
while true; do
    print_menu
    echo
    read -p "$(echo -e -n "${YELLOW}Enter your choice: ${RESET}")" choice
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
            
            #nix run github:ovyerus/bandsnatch -- run --format flac --output-folder "$BANDCAMP_MUSIC_PATH" --cookies "$COOKIE" llego202
            bandsnatch run --format flac --output-folder "$BANDCAMP_MUSIC_PATH" --cookies "$COOKIE" llego202
            
            echo -e "\nBacking up cache file \n"
            rsync "$BANDCAMP_MUSIC_PATH/bandcamp-collection-downloader.cache" "$BANDCAMP_HOME/"
            ;;
        2)
            echo -e "${GREEN}✔ Rsyncing bandcamp albums to the server \n From: $BANDCAMP_MUSIC_PATH/ \n To: $REMOTE_HOST_PATH${RESET}"
            eval rsync -r --info=progress2 "$BANDCAMP_MUSIC_PATH"/ "$REMOTE_HOST_PATH"
            ;;
        3)
            echo -e "${GREEN}✔ Rsyncing tidal albums to the server \n From: $TIDAL_MUSIC_PATH/ \n To: $REMOTE_HOST_PATH${RESET}"
            eval rsync -r --info=progress2 "$TIDAL_MUSIC_PATH"/ "$REMOTE_HOST_PATH"
            ;;
        4)
            echo -e "${GREEN}✔ Connecting to beets container on remote host and run 'beet import /import'${RESET}"
            ssh -t $REMOTE_HOST "sudo docker exec -u abc -it beets bash -c 'beet import /import'"
            ;;
        q|Q)
            echo -e "${BOLD}${RED}✖ Exiting. Goodbye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}⚠ Invalid option. Please choose between 1-4 or 'q' to quit.${RESET}"
            ;;
    esac

    echo
    read -p "$(echo -e -n "${YELLOW}Press Enter to continue...${RESET}")"
    clear
done
