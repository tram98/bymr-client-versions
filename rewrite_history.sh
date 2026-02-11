#!/bin/bash

set -e

# Configuration
REPO_DIR="/home/runner/work/bymr-client-versions/bymr-client-versions"
INITIAL_COMMIT="cfb890eaddde3b9d895f8b81cea3a7a8808676ed"
NEW_BRANCH="refined-history"

cd "$REPO_DIR"

# Clean up any existing state
git reset --hard HEAD 2>/dev/null || true
git clean -fd 2>/dev/null || true
git cherry-pick --abort 2>/dev/null || true

# Get list of all commits in order (from initial to latest)
echo "Getting list of commits..."
COMMITS=$(git rev-list --reverse HEAD)

# Checkout initial commit and delete old refined-history branch if it exists
git checkout copilot/refined-history 2>/dev/null || git checkout main 2>/dev/null || true
if git show-ref --verify --quiet refs/heads/$NEW_BRANCH; then
    echo "Deleting existing $NEW_BRANCH branch..."
    git branch -D $NEW_BRANCH
fi

# Create new branch from initial commit
echo "Creating new branch $NEW_BRANCH from $INITIAL_COMMIT..."
git checkout -b $NEW_BRANCH $INITIAL_COMMIT

# Process each commit (skip the initial commit itself)
COMMIT_NUM=0
for commit in $COMMITS; do
    COMMIT_NUM=$((COMMIT_NUM + 1))
    
    # Skip the initial commit
    if [ "$commit" = "$INITIAL_COMMIT" ]; then
        echo "[$COMMIT_NUM] Skipping initial commit $commit"
        continue
    fi
    
    # Get commit info
    COMMIT_MSG=$(git log -1 --format=%s $commit)
    COMMIT_AUTHOR=$(git log -1 --format='%an <%ae>' $commit)
    COMMIT_DATE=$(git log -1 --format=%aD $commit)
    
    echo ""
    echo "[$COMMIT_NUM] Processing commit: $commit"
    echo "    Message: $COMMIT_MSG"
    
    # Cherry-pick the commit (this brings all changes)
    echo "    Cherry-picking commit..."
    if git cherry-pick --no-commit $commit 2>&1; then
        echo "    Cherry-pick successful"
    else
        echo "    Cherry-pick had conflicts, resolving..."
        # For deleted files (DU status), remove them
        git status --short | grep '^DU ' | awk '{print $2}' | while read file; do
            git rm "$file" 2>/dev/null || true
        done
        # For files deleted in incoming commit (UD status), remove them
        git status --short | grep '^UD ' | awk '{print $2}' | while read file; do
            git rm "$file" 2>/dev/null || true
        done
        # For modified conflicts (UU status), take their version
        git status --short | grep '^UU ' | awk '{print $2}' | while read file; do
            git checkout --theirs "$file" 2>/dev/null || true
            git add "$file" 2>/dev/null || true
        done
        # For added by them (AU status), take their version
        git status --short | grep '^AU ' | awk '{print $2}' | while read file; do
            git checkout --theirs "$file" 2>/dev/null || true
            git add "$file" 2>/dev/null || true
        done
        # Add any remaining untracked files
        git add -A 2>/dev/null || true
    fi
    
    # Replace all symbol parameters with "dummy"
    echo "    Replacing symbol parameters with 'dummy'..."
    find scripts -type f -name "*.as" 2>/dev/null | while read file; do
        if [ -f "$file" ]; then
            sed -i 's/\(symbol="\)[^"]*\(")\)/\1dummy\2/g' "$file"
        fi
    done
    
    # Stage all changes including the dummy replacements
    git add -A
    
    # Check if there are any changes to commit
    if git diff --staged --quiet; then
        echo "    No changes in this commit"
    else
        # Commit with original author and date
        GIT_AUTHOR_NAME="${COMMIT_AUTHOR%% <*}"
        GIT_AUTHOR_EMAIL=$(echo "$COMMIT_AUTHOR" | sed 's/.*<\(.*\)>/\1/')
        GIT_AUTHOR_DATE="$COMMIT_DATE" \
        GIT_COMMITTER_DATE="$COMMIT_DATE" \
        git commit --author="$COMMIT_AUTHOR" -m "$COMMIT_MSG"
        echo "    Committed successfully"
    fi
done

echo ""
echo "History rewriting complete!"
echo "New branch: $NEW_BRANCH"
echo "Total commits in refined history: $(git rev-list --count $NEW_BRANCH)"
