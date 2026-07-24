#!/usr/bin/env bash

# Set variables
# Cookie is managed by agenix and decrypted at /run/agenix/bandcamp-cookie
COOKIE="/run/agenix/bandcamp-cookie"

BANDCAMP_MUSIC_PATH="${XDG_MUSIC_DIR:-$HOME/Music}/bandcamp"
CACHE="$BANDCAMP_MUSIC_PATH/bandcamp-collection-downloader.cache"
# Crisuflix import host
REMOTE_HOST="llego@crisuflix.tailnet.cri.su"
REMOTE_HOST_PATH="$REMOTE_HOST:/mnt/illby/transient/beets-import"

# Central cache server settings
CENTRAL_CACHE_HOST="llego@vps.tailnet.cri.su"
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
    echo -e "${CYAN}2)${RESET} Rsync bandcamp albums to crisuflix"
    echo -e "${CYAN}3)${RESET} Sync cache to central server"
    echo -e "${CYAN}4)${RESET} Show new available albums"
    echo -e "${CYAN}5)${RESET} Show cache contents"
    echo -e "${CYAN}q)${RESET} Quit"
    echo -e "${BOLD}${BLUE}======================================${RESET}"
}

merge_cache_into() {
    local source="$1"
    local destination="$2"
    local destination_dir="${destination%/*}"
    local id line

    if [ ! -f "$source" ]; then
        return
    fi

    mkdir -p "$destination_dir"
    touch "$destination"

    declare -A seen=()
    while IFS= read -r line; do
        id="${line%%|*}"
        if [ -n "$id" ]; then
            seen["$id"]=1
        fi
    done < "$destination"

    while IFS= read -r line; do
        id="${line%%|*}"
        if [ -n "$id" ] && [ -z "${seen[$id]+x}" ]; then
            printf '%s\n' "$line" >> "$destination"
            seen["$id"]=1
        fi
    done < "$source"
}

# Function to sync cache from central server
sync_cache_from_remote() {
    echo -e "${CYAN}Syncing cache from central server...${RESET}"
    if ssh -o ConnectTimeout=10 "$CENTRAL_CACHE_HOST" "test -f $CENTRAL_CACHE_PATH/bandcamp-collection-downloader.cache"; then
        local remote_cache
        remote_cache="$(mktemp)"
        rsync -e "ssh -o ConnectTimeout=10" "$CENTRAL_CACHE_FILE" "$remote_cache"
        merge_cache_into "$remote_cache" "$CACHE"
        rm -f "$remote_cache"
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

pause() {
    echo
    read -r -p "$(printf '%b' "${YELLOW}Press enter to return to the menu...${RESET}")"
}

show_cache() {
    if [ ! -f "$CACHE" ]; then
        echo -e "${YELLOW}⚠ No local cache found at $CACHE${RESET}"
        return
    fi

    echo -e "${BOLD}${BLUE}========== Cache Contents ==========${RESET}"
    nl -ba "$CACHE"
    echo -e "${BOLD}${BLUE}====================================${RESET}"
}

fetch_bandcamp_pagedata() {
    curl -fsSL -b "$COOKIE" "https://bandcamp.com/llego202" \
        | perl -0ne 'if (/id="pagedata"[^>]*data-blob="([^"]*)"/s) { my $x = $1; $x =~ s/&quot;/"/g; $x =~ s/&amp;/\&/g; $x =~ s/&#39;/\x27/g; print $x; exit }'
}

# This mirrors the collection API flow used by Bandcamp downloaders. Consider
# switching the backend to bandsnatch later if it becomes the main downloader.
show_available_albums() {
    echo -e "${GREEN}✔ Checking for new available Bandcamp albums${RESET}"
    sync_cache_from_remote

    if [ ! -f "$CACHE" ]; then
        echo -e "${YELLOW}⚠ No local cache found at $CACHE${RESET}"
        return
    fi

    local pagedata fan_id token more items page page_items total cached_count new_count
    pagedata="$(fetch_bandcamp_pagedata)"
    if [ -z "$pagedata" ]; then
        echo -e "${RED}⚠ Failed to read Bandcamp collection metadata${RESET}"
        return 1
    fi

    fan_id="$(jq -r '.fan_data.fan_id // empty' <<<"$pagedata")"
    token="$(jq -r '.collection_data.last_token // empty' <<<"$pagedata")"
    if [ -z "$fan_id" ] || [ -z "$token" ]; then
        echo -e "${RED}⚠ Failed to read Bandcamp collection pagination data${RESET}"
        return 1
    fi

    items="$(jq -r '.item_cache.collection | to_entries[].value | select(.sale_item_id != null) | [.sale_item_type, .sale_item_id, .item_title, .band_name, .item_url] | @tsv' <<<"$pagedata")"
    more="$(jq -r '.collection_data.item_count > .collection_data.batch_size' <<<"$pagedata")"

    while [ "$more" = true ]; do
        page="$(curl -fsSL -b "$COOKIE" -H "Content-Type: application/json" \
            --data "$(jq -nc --argjson fan_id "$fan_id" --arg token "$token" '{fan_id: $fan_id, older_than_token: $token}')" \
            "https://bandcamp.com/api/fancollection/1/collection_items")"
        page_items="$(jq -r '.items[] | select(.sale_item_id != null) | [.sale_item_type, .sale_item_id, .item_title, .band_name, .item_url] | @tsv' <<<"$page")"
        if [ -n "$page_items" ]; then
            items="${items}${items:+$'\n'}${page_items}"
        fi
        more="$(jq -r '.more_available' <<<"$page")"
        token="$(jq -r '.last_token // empty' <<<"$page")"
    done

    declare -A cached=()
    cached_count=0
    while IFS='|' read -r cached_id _; do
        cached_id="${cached_id#[pr]}"
        if [ -n "$cached_id" ]; then
            cached["$cached_id"]=1
            cached_count=$((cached_count + 1))
        fi
    done < "$CACHE"

    total=0
    new_count=0
    echo -e "${BOLD}${BLUE}========== New Available Albums ==========${RESET}"
    while IFS=$'\t' read -r sale_type sale_item_id title artist url; do
        if [ -z "$sale_item_id" ]; then
            continue
        fi

        total=$((total + 1))
        if [ -z "${cached[$sale_item_id]+x}" ]; then
            new_count=$((new_count + 1))
            printf '%2d. %s%s | %s | %s | %s\n' "$new_count" "$sale_type" "$sale_item_id" "$title" "$artist" "$url"
        fi
    done <<<"$items"

    if [ "$new_count" -eq 0 ]; then
        echo -e "${GREEN}✔ No new albums found${RESET}"
    fi
    echo -e "${BOLD}${BLUE}==========================================${RESET}"
    echo -e "${CYAN}Fetched: $total collection items | Cache: $cached_count entries | New: $new_count${RESET}"
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

            # Create music folder if it does not exist
            if [ ! -d "$BANDCAMP_MUSIC_PATH" ]; then
                echo -e "Directory does not exist. Creating directory \n " "$BANDCAMP_MUSIC_PATH"
                mkdir -p "$BANDCAMP_MUSIC_PATH"
            fi

            # Sync cache from central server before downloading.
            sync_cache_from_remote

            bandcamp-collection-downloader -f flac -d "$BANDCAMP_MUSIC_PATH" -c "$COOKIE" llego202

            echo -e "\n${YELLOW}Note: Remember to sync cache to central server (option 3) when ready${RESET}"
            ;;
        2)
            echo -e "${GREEN}✔ Rsyncing bandcamp albums to the server \n From: $BANDCAMP_MUSIC_PATH/ \n To: $REMOTE_HOST_PATH${RESET}"
            rsync -r --chmod=Dg+s,Dg+rwX,Fg+rw --info=progress2 "$BANDCAMP_MUSIC_PATH"/ "$REMOTE_HOST_PATH"
            ;;
        3)
            echo -e "${GREEN}✔ Syncing cache to central server${RESET}"
            sync_cache_to_remote
            ;;
        4)
            show_available_albums
            pause
            ;;
        5)
            show_cache
            pause
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
