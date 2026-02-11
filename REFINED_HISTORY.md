# Refined History Branch

## Overview

The `refined-history` branch has been successfully created from the repository's commit history. This branch contains all the meaningful code changes while normalizing the Embed symbol parameters to remove noise from the diff history.

## What Was Done

1. **Started from the initial commit**: `cfb890e` (Added README)
2. **Processed all 40 commits** in chronological order
3. **For each commit**:
   - Cherry-picked the commit to bring in all changes
   - Resolved any conflicts by accepting the incoming changes
   - Replaced all `symbol="symbolXXXX"` parameters with `symbol="dummy"` in all `.as` files
   - Committed the result with the original author, date, and message

## Results

- **Total commits in refined-history**: 39 (initial + 38 version updates)
- **All Embed symbols normalized**: Every `[Embed(source="/_assets/assets.swf", symbol="...")]` now has `symbol="dummy"`
- **Meaningful changes preserved**: Real code changes (logic, algorithms, new features) are all intact
- **Reduced noise**: File changes that only contained Embed symbol updates no longer appear in the diffs

## Example

### Before (original commit `2073a49`):
- 42 files changed
- Many files only had changes like:
  ```diff
  -   [Embed(source="/_assets/assets.swf", symbol="symbol3022")]
  +   [Embed(source="/_assets/assets.swf", symbol="symbol3039")]
  ```

### After (refined commit `cee98e2`):
- 13 files changed
- Only files with real code changes appear in the diff
- Embed symbols are normalized to `symbol="dummy"` across all files

## Verification

You can verify the changes:

```bash
# Check that all symbols are "dummy"
grep -r 'symbol=' scripts/ | grep -v 'symbol="dummy"'
# Should return no results

# Compare a refined commit with its original
git show cee98e2 --stat    # Refined version
git show 2073a49 --stat    # Original version

# View the actual code changes
git show cee98e2 -- scripts/BASE.as
```

## Branch Information

- **Branch name**: `refined-history`
- **Base commit**: `cfb890e` (Added README)
- **HEAD commit**: `82c384b` (Update README.md)
- **Total commits**: 39

## Pushing the Branch

The `refined-history` branch has been created locally. To push it to GitHub, you'll need to run:

```bash
git push origin refined-history:refined-history
```

Note: Due to authentication restrictions in this environment, the branch could not be automatically pushed. Please push it manually or request the repository maintainer to do so.

## Script

The script used to create this branch is available at `rewrite_history.sh` in the repository root. It can be run again if needed:

```bash
./rewrite_history.sh
```

The script will:
1. Delete any existing `refined-history` branch
2. Create a new one from the initial commit
3. Process all commits in order
4. Normalize all Embed symbols to "dummy"
5. Preserve all meaningful code changes
