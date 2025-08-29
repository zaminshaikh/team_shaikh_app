#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH # change working directory to the root of your cloned repo.

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Build iOS configuration for release mode
flutter build ios --config-only --release

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Configure Git to use HTTPS instead of SSH for GitHub repositories
git config --global url."https://github.com/".insteadOf git@github.com:
git config --global url."https://".insteadOf git://

# Configure CocoaPods to use CDN
export COCOAPODS_REPO_UPDATE_SILENT=1
export COCOAPODS_REPO_UPDATE_TIMEOUT=30

# Install CocoaPods dependencies with retry logic
cd ios

# Clean CocoaPods cache to avoid stale network issues
pod cache clean --all

for i in {1..3}; do
    echo "Attempt $i: Running pod install..."
    if pod install --repo-update; then
        echo "Pod install succeeded"
        break
    else
        echo "Pod install failed on attempt $i"
        if [ $i -eq 3 ]; then
            echo "All pod install attempts failed"
            exit 1
        fi
        sleep 10
    fi
done

exit 0
