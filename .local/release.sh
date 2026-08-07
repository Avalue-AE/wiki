#!/bin/bash
set -e

VERSION=`git describe --tags`
SCRIPT_DIR=$(cd $(dirname $0); pwd)
WORKSPACE="/home/workspace" 
SOURCE_DIR="$WORKSPACE/Avalue-driver"
TARGET_BOARD=$1

# 1. Check Arguments
if [ -z "$TARGET_BOARD" ]; then
    echo "Usage: $0 [BOARD_NAME]"
    exit 1
fi

# 2. Check Board Config
CONF_FILE="$SOURCE_DIR/configs/boards/$TARGET_BOARD.conf"
if [ ! -f "$CONF_FILE" ]; then
    echo "Error: Board config '$TARGET_BOARD' not found at:"
    echo "       $CONF_FILE"
    exit 1
fi

TARGET_PACKAGE_NAME="Avalue-driver-$VERSION-$TARGET_BOARD"
cd $WORKSPACE

echo "=== Packaging for $TARGET_BOARD ==="

# 3. Copy Source
echo "-> Copying source..."
rm -rf "$TARGET_PACKAGE_NAME"
cp -r "$SOURCE_DIR" "$TARGET_PACKAGE_NAME"

# 4. Configure & Clean
cd "$TARGET_PACKAGE_NAME"

echo "-> Generating Board Header..."
make BOARD_NAME=$TARGET_BOARD clean config

echo "-> Writing VERSION file for post-package rebuilds..."
echo "$VERSION" > VERSION

echo "-> Cleaning up development files..."
rm -rf .git .vscode .gitignore .gitlab-ci.yml .local .clang-format .editorconfig CLAUDE.md

# A board name may itself be a symlink alias (e.g. ADP-226-01.conf ->
# ADP-226.conf), and that alias may chain through more than one hop. Walk
# the chain one hop at a time (readlink -f would jump straight to the final
# target and skip any intermediate hop names) and keep every hop, or the
# package ships a dangling symlink in the middle of the chain.
KEEP_NAMES="$TARGET_BOARD.conf"
CUR="configs/boards/$TARGET_BOARD.conf"
HOPS=0
while [ -L "$CUR" ]; do
    HOPS=$((HOPS + 1))
    if [ "$HOPS" -gt 20 ]; then
        echo "Error: symlink chain for $TARGET_BOARD.conf is too deep (possible loop)"
        exit 1
    fi
    NEXT=$(readlink "$CUR")
    KEEP_NAMES="$KEEP_NAMES $NEXT"
    CUR="configs/boards/$NEXT"
done

PRUNE_EXCLUDES=""
for NAME in $KEEP_NAMES; do
    PRUNE_EXCLUDES="$PRUNE_EXCLUDES ! -name $NAME"
done

find configs/boards/ \( -type f -o -type l \) -name "*.conf" $PRUNE_EXCLUDES -delete
echo "-> Kept only: $KEEP_NAMES"

cd $WORKSPACE

# 5. Archive
echo "-> Creating Tarball..."
TAR_NAME="$TARGET_PACKAGE_NAME.tar.gz"
tar zcf "$TAR_NAME" "$TARGET_PACKAGE_NAME"

# 6. Cleanup
echo "-> Cleaning temporary files..."
rm -rf "$TARGET_PACKAGE_NAME"

echo "=== Done ($TAR_NAME) ==="
