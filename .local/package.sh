#!/bin/bash
set -e

VERSION=`git describe --tags`
SCRIPT_DIR=$(cd $(dirname $0); pwd)
WORKSPACE="/home/workspace" 
SOURCE_DIR="$WORKSPACE/Avalue-driver"

TARGET_PACKAGE_NAME="Avalue-driver-$VERSION"
cd $WORKSPACE

echo "=== Packaging for $TARGET_PACKAGE_NAME ==="

echo "-> Copying source..."
rm -rf "$TARGET_PACKAGE_NAME"
cp -r "$SOURCE_DIR" "$TARGET_PACKAGE_NAME"

cd "$TARGET_PACKAGE_NAME"
make clean

echo "-> Writing VERSION file for post-package rebuilds..."
echo "$VERSION" > VERSION

echo "-> Cleaning up development files..."
rm -rf .git .vscode .gitignore .gitlab-ci.yml .local .clang-format .editorconfig CLAUDE.md

cd $WORKSPACE

echo "-> Creating Tarball..."
TAR_NAME="$TARGET_PACKAGE_NAME.tar.gz"
tar zcf "$TAR_NAME" "$TARGET_PACKAGE_NAME"

echo "-> Cleaning temporary files..."
rm -rf "$TARGET_PACKAGE_NAME"

echo "=== Package $TAR_NAME Completed ==="
