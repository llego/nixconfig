#!/usr/bin/env bash
# Post-commit hook for nixconfig supermemory tracking
# Runs after every commit to log configuration changes

set -e

# Get commit info
COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
COMMIT_DATE=$(git log -1 --pretty=%ci | cut -d' ' -f1)
COMMIT_SUBJECT=$(git log -1 --pretty=%s)

# Get changed files
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD | tr '\n' ', ' | sed 's/, $//')

# Initialize variables
AFFECTED_HOSTS=""
CATEGORY=""
IS_DOC_UPDATE=false

# Function to detect affected hosts from file paths
detect_hosts() {
    local hosts=""
    local files="$1"
    
    # Check for each host
    if echo "$files" | grep -q "hosts/laptop"; then
        hosts="${hosts}laptop "
    fi
    if echo "$files" | grep -q "hosts/vps"; then
        hosts="${hosts}vps "
    fi
    if echo "$files" | grep -q "hosts/crisuflix"; then
        hosts="${hosts}crisuflix "
    fi
    if echo "$files" | grep -q "hosts/rpi5"; then
        hosts="${hosts}rpi5 "
    fi
    
    # Shared modules affect all hosts
    if echo "$files" | grep -q "modules/core"; then
        hosts="${hosts}all-hosts "
    fi
    if echo "$files" | grep -q "flake.nix"; then
        hosts="${hosts}all-hosts "
    fi
    if echo "$files" | grep -q "secrets.nix"; then
        hosts="${hosts}all-hosts "
    fi
    
    # Trim trailing space
    echo "$hosts" | sed 's/ $//'
}

# Function to categorize change
categorize_change() {
    local msg="$1"
    local files="$2"
    local category="other"
    
    # Check commit message for keywords
    if echo "$msg" | grep -qi "^add\| add \|^feat"; then
        category="add"
    elif echo "$msg" | grep -qi "^remove\| delete\| cleanup\| drop"; then
        category="remove"
    elif echo "$msg" | grep -qi "^fix\| bugfix\| hotfix"; then
        category="fix"
    elif echo "$msg" | grep -qi "^update\| bump\| upgrade"; then
        category="update"
    elif echo "$msg" | grep -qi "^move\| migrate\| relocate"; then
        category="move"
    elif echo "$msg" | grep -qi "^refactor\| rewrite\| restructure"; then
        category="refactor"
    elif echo "$msg" | grep -qi "^docs\| documentation\| readme\| comment"; then
        category="docs"
    elif echo "$msg" | grep -qi "agenix\| secret"; then
        category="secrets"
    fi
    
    # Check files for additional context
    if echo "$files" | grep -q "README.md\|AGENTS.md\|.md$"; then
        if [ "$category" = "other" ]; then
            category="docs"
        fi
    fi
    
    echo "$category"
}

# Detect hosts and category
AFFECTED_HOSTS=$(detect_hosts "$CHANGED_FILES")
CATEGORY=$(categorize_change "$COMMIT_SUBJECT" "$CHANGED_FILES")

# Check if this is a documentation update
if echo "$CHANGED_FILES" | grep -q "README.md\|AGENTS.md"; then
    IS_DOC_UPDATE=true
fi

# Generate summary (first line of commit message or truncate)
SUMMARY="$COMMIT_SUBJECT"
if [ ${#SUMMARY} -gt 100 ]; then
    SUMMARY="${SUMMARY:0:100}..."
fi

# Build supermemory content
MEMORY_CONTENT="NIXCONFIG CHANGE: [${COMMIT_DATE}]"

if [ -n "$AFFECTED_HOSTS" ]; then
    MEMORY_CONTENT="${MEMORY_CONTENT} ${AFFECTED_HOSTS}"
fi

MEMORY_CONTENT="${MEMORY_CONTENT} - ${CATEGORY}

COMMIT: ${COMMIT_HASH}
MESSAGE: ${COMMIT_SUBJECT}

AFFECTED HOSTS: ${AFFECTED_HOSTS:-none specifically}
CATEGORY: ${CATEGORY}
FILES: ${CHANGED_FILES}

SUMMARY:
${COMMIT_MSG}
"

# Store in supermemory using the MCP tool
# Note: This requires the supermemory MCP server to be available
if command -v supermemory &> /dev/null; then
    supermemory add \
        --type configuration-change \
        --scope user \
        --content "$MEMORY_CONTENT"
fi

# Special handling for documentation updates
if [ "$IS_DOC_UPDATE" = true ]; then
    DOC_MEMORY="NIXCONFIG DOCS UPDATE: [${COMMIT_DATE}]

COMMIT: ${COMMIT_HASH}
DOC FILES: $(echo "$CHANGED_FILES" | grep -o 'README.md\|AGENTS.md' | tr '\n' ', ' | sed 's/, $//')

KEY CHANGES:
${COMMIT_MSG}

AI AGENT IMPACT: Documentation updated - check for new patterns or infrastructure info
"
    
    if command -v supermemory &> /dev/null; then
        supermemory add \
            --type documentation-update \
            --scope user \
            --content "$DOC_MEMORY"
    fi
fi

# Also log to local file as backup
LOG_DIR="$(git rev-parse --show-toplevel)/.nixconfig-changes"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/$(date +%Y-%m).log"
echo "---" >> "$LOG_FILE"
echo "DATE: $COMMIT_DATE" >> "$LOG_FILE"
echo "COMMIT: $COMMIT_HASH" >> "$LOG_FILE"
echo "HOSTS: $AFFECTED_HOSTS" >> "$LOG_FILE"
echo "CATEGORY: $CATEGORY" >> "$LOG_FILE"
echo "MESSAGE: $COMMIT_SUBJECT" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit 0
