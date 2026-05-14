#!/usr/bin/env bash
# adlibris-downloader — fetch watermarked EPUBs from Adlibris → Booklore bookdrop
#
# Phase 1: cookies supplied via config file
# Phase 2 (TODO, laptop): auto-extract from Zen browser's cookies.sqlite

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/adlibris-downloader"
CONFIG_FILE="$CONFIG_DIR/config"
DOWNLOADED_FILE="$CONFIG_DIR/downloaded.txt"
TMP_DIR="/tmp/adlibris-downloader"

# Defaults (overridable in config file)
CRISUFLIX_HOST="llego@100.123.67.48"
CRISUFLIX_BOOKDROP="/mnt/illby/transient/sabnzbd-downloads/complete/books"
ADLIBRIS_BASE="https://www.adlibris.com/fi"
ZEN_PROFILE_PATH=""  # Phase 2: set to path of cookies.sqlite

# ── Colors ────────────────────────────────────────────────────────────────────

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
DIM="\e[2m"
RESET="\e[0m"

# ── Helpers ───────────────────────────────────────────────────────────────────

die() { echo -e "${RED}✖ $*${RESET}" >&2; exit 1; }
info() { echo -e "${CYAN}→ $*${RESET}"; }
ok() { echo -e "${GREEN}✔ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $*${RESET}"; }

# ── Setup ─────────────────────────────────────────────────────────────────────

mkdir -p "$CONFIG_DIR" "$TMP_DIR"
touch "$DOWNLOADED_FILE"

# Load config file
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<EOF
# Adlibris downloader config
# Phase 1: paste cookie values from browser DevTools

ADLIBRIS_AUTH=""
ADLIBRIS_ADSS=""

# rsync destination
CRISUFLIX_HOST="llego@100.123.67.48"
CRISUFLIX_BOOKDROP="/mnt/illby/transient/sabnzbd-downloads/complete/books"

# Phase 2 (laptop only): path to Zen browser cookies.sqlite
# ZEN_PROFILE_PATH="~/.zen/<profile>/cookies.sqlite"
EOF
    die "Config file created at $CONFIG_FILE\nPlease fill in ADLIBRIS_AUTH and ADLIBRIS_ADSS cookie values."
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ── Cookie management ─────────────────────────────────────────────────────────

# Phase 2: auto-extract cookies from Zen browser (laptop)
extract_zen_cookies() {
    local profile_path="$1"
    local db_copy="$TMP_DIR/cookies.sqlite"

    info "Extracting cookies from Zen browser..."
    cp "$profile_path" "$db_copy"

    ADLIBRIS_AUTH=$(sqlite3 "$db_copy" \
        "SELECT value FROM moz_cookies WHERE host LIKE '%adlibris.com' AND name='.adlibrisauth' LIMIT 1;")
    ADLIBRIS_ADSS=$(sqlite3 "$db_copy" \
        "SELECT value FROM moz_cookies WHERE host LIKE '%adlibris.com' AND name='adss' LIMIT 1;")
    rm -f "$db_copy"
}

# If ZEN_PROFILE_PATH is set, extract cookies automatically (Phase 2)
if [[ -n "$ZEN_PROFILE_PATH" ]]; then
    expanded_path="${ZEN_PROFILE_PATH/#\~/$HOME}"
    if [[ -f "$expanded_path" ]]; then
        extract_zen_cookies "$expanded_path"
    else
        warn "ZEN_PROFILE_PATH set but file not found: $expanded_path"
        warn "Falling back to config file cookies"
    fi
fi

[[ -z "$ADLIBRIS_AUTH" ]] && die "ADLIBRIS_AUTH is not set in $CONFIG_FILE"
[[ -z "$ADLIBRIS_ADSS" ]] && die "ADLIBRIS_ADSS is not set in $CONFIG_FILE"

COOKIE_HEADER="Cookie: .adlibrisauth=${ADLIBRIS_AUTH}; adss=${ADLIBRIS_ADSS}; culture=fi-FI"

# ── Session warming (simulate real browser behavior) ─────────────────────────────

warm_session() {
    info "Warming session..."
    
    # Visit main page first (like a real user)
    curl -s -L \
        --compressed \
        --connect-timeout 15 \
        --max-time 30 \
        -H "$COOKIE_HEADER" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.9,fi;q=0.8,sv;q=0.7" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "DNT: 1" \
        -H "Connection: keep-alive" \
        -H "Upgrade-Insecure-Requests: 1" \
        -H "Sec-Fetch-Dest: document" \
        -H "Sec-Fetch-Mode: navigate" \
        -H "Sec-Fetch-Site: none" \
        -H "Sec-Fetch-User: ?1" \
        -H "Cache-Control: max-age=0" \
        "$ADLIBRIS_BASE/" > /dev/null
    
    # Brief pause like a real user
    sleep 2
    
    # Visit account area (like navigating to my books)
    curl -s -L \
        --compressed \
        --connect-timeout 15 \
        --max-time 30 \
        -H "$COOKIE_HEADER" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.9,fi;q=0.8,sv;q=0.7" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "DNT: 1" \
        -H "Connection: keep-alive" \
        -H "Upgrade-Insecure-Requests: 1" \
        -H "Sec-Fetch-Dest: document" \
        -H "Sec-Fetch-Mode: navigate" \
        -H "Sec-Fetch-Site: same-origin" \
        -H "Sec-Fetch-User: ?1" \
        -H "Referer: $ADLIBRIS_BASE/" \
        -H "Cache-Control: max-age=0" \
        "$ADLIBRIS_BASE/asiakastili/" > /dev/null
    
    sleep 1
}

# ── Library scraping ──────────────────────────────────────────────────────────

# Enhanced browser simulation to bypass bot detection
fetch_page() {
    local page="$1"
    
    # Add random delay between 1-3 seconds to simulate human behavior
    sleep $(( (RANDOM % 3) + 1 ))
    
    curl -s -L \
        --compressed \
        --connect-timeout 30 \
        --max-time 60 \
        --retry 3 \
        --retry-delay 2 \
        -H "$COOKIE_HEADER" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.9,fi;q=0.8,sv;q=0.7" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "DNT: 1" \
        -H "Connection: keep-alive" \
        -H "Upgrade-Insecure-Requests: 1" \
        -H "Sec-Fetch-Dest: document" \
        -H "Sec-Fetch-Mode: navigate" \
        -H "Sec-Fetch-Site: same-origin" \
        -H "Sec-Fetch-User: ?1" \
        -H "Cache-Control: max-age=0" \
        -H "Referer: $ADLIBRIS_BASE/asiakastili/" \
        -H "Origin: $ADLIBRIS_BASE" \
        "$ADLIBRIS_BASE/asiakastili/library?page=${page}"
}

# Parse books from a library page HTML
# Outputs lines: variantId|type|title|author
parse_books() {
    local html="$1"

    # Extract product-list-item blocks and parse each one
    # We process the HTML line by line, tracking state per book entry
    local variant="" type="" title="" author=""

    while IFS= read -r line; do
        # Detect download link — variantId and type
        if echo "$line" | grep -q "tuote/download"; then
            variant=$(echo "$line" | sed -n 's/.*variantId=\([a-f0-9-]*\).*/\1/p')
            if echo "$line" | grep -q "EpubWatermark"; then
                type="EpubWatermark"
            elif echo "$line" | grep -q "PDFWatermark"; then
                type="PDFWatermark"
            else
                type="DRM"
            fi
        fi

        # Detect title (inside <h3>)
        if echo "$line" | grep -q "<h3>"; then
            title=$(echo "$line" | sed 's/.*<h3>[[:space:]]*//' | sed 's/[[:space:]]*<\/h3>.*//' | sed 's/&#[0-9]*;//g' | sed 's/&amp;/\&/g')
        fi

        # Detect author (inside the author <a> tag)
        if echo "$line" | grep -q 'filter=author'; then
            author=$(echo "$line" | sed 's/.*filter=author[^>]*>//' | sed 's/<\/a>.*//' | sed 's/%20/ /g')
        fi

        # End of a product-list-item block — emit record if we have all fields
        if echo "$line" | grep -q "digital-formats" && [[ -n "$variant" && -n "$title" && -n "$author" ]]; then
            echo "${variant}|${type}|${title}|${author}"
            variant=""; type=""; title=""; author=""
        fi
    done <<< "$html"
}

# Fetch all pages until empty
fetch_all_books() {
    local page=1
    local all_books=()

    info "Fetching Adlibris digital library..."

    while true; do
        local html
        html=$(fetch_page "$page")

        # Check if logged in (library page shows "Digitaalinen kirjasto")
        if ! echo "$html" | grep -q "digital-product-item-list"; then
            if [[ $page -eq 1 ]]; then
                die "No books found — check your cookie values (session may have expired)"
            fi
            break
        fi

        local page_books
        page_books=$(parse_books "$html")

        if [[ -z "$page_books" ]]; then
            break
        fi

        while IFS= read -r book; do
            all_books+=("$book")
        done <<< "$page_books"

        # Check for next page link
        if ! echo "$html" | grep -q "page=$((page + 1))"; then
            break
        fi

        ((page++))
    done

    printf '%s\n' "${all_books[@]}"
}

# ── Download ──────────────────────────────────────────────────────────────────

download_book() {
    local variant="$1" title="$2" author="$3"
    local safe_name
    safe_name=$(printf '%s - %s' "${author}" "${title}" | tr -d '"?' | tr -d $'\\\\' | tr '/:*<>|' '_' | sed 's/  */ /g')
    local dest="$TMP_DIR/${safe_name}.epub"

    info "Downloading: ${title} — ${author}"

    # Add small delay before download to simulate user interaction
    sleep $(( (RANDOM % 2) + 1 ))
    
    local http_code
    http_code=$(curl -s -L -w "%{http_code}" \
        --compressed \
        --connect-timeout 30 \
        --max-time 300 \
        --retry 2 \
        --retry-delay 3 \
        -H "$COOKIE_HEADER" \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.9,fi;q=0.8,sv;q=0.7" \
        -H "Accept-Encoding: gzip, deflate, br" \
        -H "DNT: 1" \
        -H "Connection: keep-alive" \
        -H "Sec-Fetch-Dest: document" \
        -H "Sec-Fetch-Mode: navigate" \
        -H "Sec-Fetch-Site: same-origin" \
        -H "Referer: $ADLIBRIS_BASE/asiakastili/library" \
        -H "Cache-Control: no-cache" \
        -H "Pragma: no-cache" \
        -o "$dest" \
        "$ADLIBRIS_BASE/tuote/download?variantId=${variant}&selectedVersion=EpubWatermark")

    if [[ "$http_code" != "200" ]]; then
        warn "HTTP $http_code for: $title"
        rm -f "$dest"
        return 1
    fi

    # Verify it looks like an EPUB (ZIP magic bytes)
    if ! file "$dest" | grep -qiE "epub|zip|java archive"; then
        warn "Download doesn't look like an EPUB: $title"
        rm -f "$dest"
        return 1
    fi

    ok "Downloaded: ${safe_name}.epub"

    info "Rsyncing to crisuflix bookdrop..."
    if rsync -e "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no" \
        "$dest" \
        "${CRISUFLIX_HOST}:${CRISUFLIX_BOOKDROP}/"; then
        ok "Sent to bookdrop: ${safe_name}.epub"
        echo "$variant" >> "$DOWNLOADED_FILE"
        rm -f "$dest"
        return 0
    else
        warn "rsync failed for: $title (file kept at $dest)"
        return 1
    fi
}

# ── TUI ───────────────────────────────────────────────────────────────────────

print_header() {
    clear
    echo -e "${BOLD}${BLUE}════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${BLUE}       Adlibris → Booklore Downloader   ${RESET}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════${RESET}"
    echo
}

main_menu() {
    print_header
    echo -e "${CYAN}1)${RESET} Download new books (not yet in library)"
    echo -e "${CYAN}2)${RESET} Browse all books (pick any to download)"
    echo -e "${CYAN}3)${RESET} Refresh cookies from Zen browser"
    echo -e "${CYAN}q)${RESET} Quit"
    echo
    read -r -p "$(printf '%b' "${YELLOW}Choice: ${RESET}")" choice
    echo
    echo "$choice"
}

run_fzf_picker() {
    local mode="$1"   # "new" or "all"
    shift
    local books=("$@")

    local fzf_input=()
    local downloaded_variants
    downloaded_variants=$(cat "$DOWNLOADED_FILE")

    for book in "${books[@]}"; do
        local variant type title author
        IFS='|' read -r variant type title author <<< "$book"

        # Skip DRM books entirely
        [[ "$type" == "DRM" ]] && continue

        local status_tag=""
        local display_type=""

        if echo "$downloaded_variants" | grep -qF "$variant"; then
            [[ "$mode" == "new" ]] && continue
            status_tag="${DIM}[downloaded]${RESET}"
        else
            status_tag="${GREEN}[new]${RESET}"
        fi

        if [[ "$type" == "PDFWatermark" ]]; then
            display_type="${DIM}PDF${RESET}"
        else
            display_type="EPUB"
        fi

        fzf_input+=("$(printf '%s\t%b %-40s  %s  %b' \
            "$variant" "$status_tag" "$title" "$author" "$display_type")")
    done

    if [[ ${#fzf_input[@]} -eq 0 ]]; then
        if [[ "$mode" == "new" ]]; then
            warn "No new books found — all books already downloaded."
        else
            warn "No downloadable books found."
        fi
        return 1
    fi

    local header_text
    if [[ "$mode" == "new" ]]; then
        header_text="New books — Tab to select multiple, Enter to confirm, Esc to cancel"
    else
        header_text="All books — Tab to select multiple, Enter to confirm, Esc to cancel"
    fi

    printf '%s\n' "${fzf_input[@]}" | \
        fzf --multi \
            --ansi \
            --header="$header_text" \
            --prompt="Select books > " \
            --preview-window=hidden \
            --bind="ctrl-a:select-all" | \
        cut -f1
}

# ── Main ──────────────────────────────────────────────────────────────────────

# Fetch books once at startup
ALL_BOOKS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && ALL_BOOKS+=("$line")
done < <(fetch_all_books)

total=${#ALL_BOOKS[@]}
drm_count=$(printf '%s\n' "${ALL_BOOKS[@]}" | grep -c '|DRM|' || true)
epub_count=$(printf '%s\n' "${ALL_BOOKS[@]}" | grep -c 'EpubWatermark' || true)
downloaded_count=$(wc -l < "$DOWNLOADED_FILE")

echo
echo -e "${BOLD}Library:${RESET} $total books total  |  $epub_count watermarked EPUB  |  $drm_count Adobe DRM (skipped)  |  $downloaded_count already downloaded"
echo

# Warm up the session before starting user interaction
warm_session

while true; do
    choice=$(main_menu)

    case "$choice" in
        1)
            selected=$(run_fzf_picker "new" "${ALL_BOOKS[@]}") || { read -r -p "Press Enter to continue..."; continue; }
            ;;
        2)
            selected=$(run_fzf_picker "all" "${ALL_BOOKS[@]}") || { read -r -p "Press Enter to continue..."; continue; }
            ;;
        3)
            if [[ -z "$ZEN_PROFILE_PATH" ]]; then
                warn "ZEN_PROFILE_PATH not set in config — cookie refresh only works on laptop."
                read -r -p "Press Enter to continue..."
                continue
            fi
            expanded_path="${ZEN_PROFILE_PATH/#\~/$HOME}"
            extract_zen_cookies "$expanded_path"
            ok "Cookies refreshed from Zen browser."
            COOKIE_HEADER="Cookie: .adlibrisauth=${ADLIBRIS_AUTH}; adss=${ADLIBRIS_ADSS}; culture=fi-FI"
            read -r -p "Press Enter to continue..."
            continue
            ;;
        q|Q)
            echo -e "${BOLD}${RED}✖ Goodbye!${RESET}"
            exit 0
            ;;
        *)
            warn "Invalid option."
            read -r -p "Press Enter to continue..."
            continue
            ;;
    esac

    if [[ -z "$selected" ]]; then
        info "No books selected."
        read -r -p "Press Enter to continue..."
        continue
    fi

    # Process selected variantIds
    success=0; failed=0
    while IFS= read -r variant; do
        [[ -z "$variant" ]] && continue
        # Look up title and author from ALL_BOOKS
        for book in "${ALL_BOOKS[@]}"; do
            IFS='|' read -r bvariant _btype btitle bauthor <<< "$book"
            if [[ "$bvariant" == "$variant" ]]; then
                if download_book "$variant" "$btitle" "$bauthor"; then
                    ((success++))
                else
                    ((failed++))
                fi
                break
            fi
        done
    done <<< "$selected"

    echo
    echo -e "${BOLD}Done:${RESET} ${GREEN}$success downloaded${RESET}  |  ${RED}$failed failed${RESET}"
    echo
    read -r -p "Press Enter to continue..."

    # Refresh downloaded count
    downloaded_count=$(wc -l < "$DOWNLOADED_FILE")
done
