#!/bin/bash

###
# Script will :
#  - Backup your default.store* files to Desktop
#  - Remove default.store* files from "Application Support"
#  - Remove UserDefaults for Bundle
#  - Remove app from "Application Support"
#  - (optional: -d) remove Derived data
###

# Check if a bundle identifier is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <bundle_identifier>"
    exit 1
fi

BUNDLE_ID="$1"
DELETE_DERIVED_DATA=false

# 📌 Check -d option
while getopts "d" opt; do
  case ${opt} in
    d )
      DELETE_DERIVED_DATA=true
      ;;
    \? )
      echo "Usage: $0 <bundle_identifier> [-d]"
      exit 1
      ;;
  esac
done

DATABASE_PATH="$HOME/Library/Application Support"
CURRENT_DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$HOME/Desktop/Backup_${BUNDLE_ID}_${CURRENT_DATE}"

APP_PATH="$HOME/Library/Application Support/$BUNDLE_ID"

DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData/"

echo "🚀 Cleaning data for application: $BUNDLE_ID"

# 🗂 Create backup directory
mkdir -p "$BACKUP_DIR"

# 🛠 Backup "default.store*" files from Application Support
if [ -d "$DATABASE_PATH" ]; then
    echo "📦 Backing up default.store* files..."
    find "$DATABASE_PATH" -type f -name "default.store*" -exec cp {} "$BACKUP_DIR" \; > /dev/null 2>&1
    echo "✅ Backup completed at $BACKUP_DIR"
    echo "🗑 Removing default.store files at $DATABASE_PATH"
    find "$DATABASE_PATH" -type f -name "default.store*" -exec rm -f {} \; > /dev/null 2>&1
else
    echo "✅ No default.store found."
fi

# 🗑 Remove UserDefaults
echo "🗑 Removing UserDefaults..."
defaults delete "$BUNDLE_ID" 2>/dev/null || echo "⚠️ Could not remove UserDefaults (possibly already deleted)."

# 🗑 Remove app from Application Support
if [ -d "$APP_PATH" ]; then
    echo "🗑 Removing app from \"Application Support\"..."
    rm -rf "$APP_PATH"
else
    echo "✅ No app found."
fi

# 🗑 Remove Xcode DerivedData
if [ "$DELETE_DERIVED_DATA" = true ]; then
echo "🗑 Removing DerivedData..."
rm -rf "$DERIVED_DATA_PATH"/*
else
    echo "⏭ Skipping DerivedData deletion (use -d to enable)."
fi

echo "🎉 Cleanup completed for $BUNDLE_ID!"
