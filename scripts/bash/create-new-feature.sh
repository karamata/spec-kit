#!/usr/bin/env bash

set -e

JSON_MODE=false
DESC_MODE=false
SHORT_DESC=""
ARGS=()
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --json) JSON_MODE=true ;;
        --desc) DESC_MODE=true ;;
        --help|-h) echo "Usage: $0 [--json] [--desc <short_description>] <feature_description>"; exit 0 ;;
        *) 
            if [ "$DESC_MODE" = true ]; then
                SHORT_DESC="$arg"
                DESC_MODE=false
            else
                ARGS+=("$arg")
            fi
            ;;
    esac
    i=$((i + 1))
done

FEATURE_DESCRIPTION="${ARGS[*]}"
if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "Usage: $0 [--json] [--desc <short_description>] <feature_description>" >&2
    exit 1
fi

# Function to find the repository root by searching for existing project markers
# Prioritizes .specify directory over .git to handle nested git repositories
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        # Check for .specify first (project root marker)
        if [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    
    # If no .specify found, look for .git as fallback
    dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Resolve repository root. Prefer .specify directory when available, then fall back
# to git information, and finally to searching for repository markers.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# First try to find .specify directory (project root)
REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
if [ -n "$REPO_ROOT" ]; then
    # Check if we have git in this directory
    if [ -d "$REPO_ROOT/.git" ]; then
        HAS_GIT=true
    else
        HAS_GIT=false
    fi
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
    # Fallback to git root if no .specify found
    REPO_ROOT=$(git rev-parse --show-toplevel)
    HAS_GIT=true
else
    echo "Error: Could not determine repository root. Please run this script from within the repository." >&2
    exit 1
fi

cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# Function to generate branch name with stop word filtering and length filtering
generate_branch_name() {
    local description="$1"
    
    # Common stop words to filter out
    local stop_words="^(i|a|an|the|to|for|of|in|on|at|by|with|from|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|should|could|can|may|might|must|shall|this|that|these|those|my|your|our|their|want|need|add|get|set)$"
    
    # Convert to lowercase and split into words
    local clean_name=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g')
    
    # Filter words: remove stop words and words shorter than 3 chars (unless they're uppercase acronyms in original)
    local meaningful_words=()
    for word in $clean_name; do
        # Skip empty words
        [ -z "$word" ] && continue
        
        # Keep words that are NOT stop words AND (length >= 3 OR are potential acronyms)
        if ! echo "$word" | grep -qiE "$stop_words"; then
            if [ ${#word} -ge 3 ]; then
                meaningful_words+=("$word")
            elif echo "$description" | grep -q "\b${word^^}\b"; then
                # Keep short words if they appear as uppercase in original (likely acronyms)
                meaningful_words+=("$word")
            fi
        fi
    done
    
    # If we have meaningful words, use first 3-4 of them
    if [ ${#meaningful_words[@]} -gt 0 ]; then
        local max_words=3
        if [ ${#meaningful_words[@]} -eq 4 ]; then max_words=4; fi
        
        local result=""
        local count=0
        for word in "${meaningful_words[@]}"; do
            if [ $count -ge $max_words ]; then break; fi
            if [ -n "$result" ]; then result="$result-"; fi
            result="$result$word"
            count=$((count + 1))
        done
        echo "$result"
    else
        # Fallback to original logic if no meaningful words found
        local cleaned=$(clean_branch_name "$description")
        echo "$cleaned" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

# Generate branch name
if [ -n "$SHORT_NAME" ]; then
    # Use provided short name, just clean it up
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    # Generate from description with smart filtering
    BRANCH_SUFFIX=$(generate_branch_name "$FEATURE_DESCRIPTION")
fi

# Function to create meaningful branch name from description
create_branch_name() {
    local desc="$1"
    
    # Convert to lowercase and clean up
    local clean_desc=$(echo "$desc" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9\s]/-/g' | sed 's/\s\+/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//')
    
    # Split into words and filter meaningful ones
    local words=$(echo "$clean_desc" | tr '-' '\n' | grep -v '^$')
    
    # Remove common stop words and short words
    local filtered_words=$(echo "$words" | grep -v -E '^(the|a|an|and|or|but|in|on|at|to|for|of|with|by|from|up|about|into|through|during|before|after|above|below|between|among|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|could|should|may|might|must|can|shall)$' | grep -E '^.{3,}$')
    
    # Take up to 4 meaningful words, but prioritize important ones
    local branch_words=$(echo "$filtered_words" | head -4 | tr '\n' '-' | sed 's/-$//')
    
    # If we have meaningful words, use them; otherwise fallback to first 3 words
    if [ -n "$branch_words" ]; then
        echo "$branch_words"
    else
        echo "$clean_desc" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//'
    fi
}

NEXT=$((HIGHEST + 1))
FEATURE_NUM=$(printf "%03d" "$NEXT")

# Use SHORT_DESC if provided, otherwise use FEATURE_DESCRIPTION for branch naming
BRANCH_DESC="${SHORT_DESC:-$FEATURE_DESCRIPTION}"
BRANCH_WORDS=$(create_branch_name "$BRANCH_DESC")
BRANCH_NAME="${FEATURE_NUM}-${BRANCH_WORDS}"

if [ "$HAS_GIT" = true ]; then
    git checkout -b "$BRANCH_NAME"
else
    >&2 echo "[specify] Warning: Git repository not detected; skipped branch creation for $BRANCH_NAME"
fi

FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"
mkdir -p "$FEATURE_DIR"

TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"
SPEC_FILE="$FEATURE_DIR/spec.md"
if [ -f "$TEMPLATE" ]; then cp "$TEMPLATE" "$SPEC_FILE"; else touch "$SPEC_FILE"; fi

# Set the SPECIFY_FEATURE environment variable for the current session
export SPECIFY_FEATURE="$BRANCH_NAME"

if $JSON_MODE; then
    printf '{"BRANCH_NAME":"%s","SPEC_FILE":"%s","FEATURE_NUM":"%s"}\n' "$BRANCH_NAME" "$SPEC_FILE" "$FEATURE_NUM"
else
    echo "BRANCH_NAME: $BRANCH_NAME"
    echo "SPEC_FILE: $SPEC_FILE"
    echo "FEATURE_NUM: $FEATURE_NUM"
    echo "SPECIFY_FEATURE environment variable set to: $BRANCH_NAME"
fi
