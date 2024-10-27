#!/bin/bash

# Defaults
PLATFORM="iOS Simulator"
DEVICE="iPhone 16 Pro Max"
OS="latest"

# Required
APP=""
BUNDLE_ID=""

usage() {
    echo "Usage: $0 --platform <platform> --app <app_name> --bundle-id <bundle_id> [--device <device>] [--os <os_version>]"
    echo "  --platform <platform>  Specify the platform: 'macOS' or 'iOS Simulator' (default: $PLATFORM)"
    echo "  --app <app_name>       (Required) Specify the app scheme"
    echo "  --bundle-id <bundle_id>(Required) Specify the app bundle identifier"
    echo "  --device <device>      Specify the device (for iOS Simulator) (default: $DEVICE)"
    echo "  --os <os_version>      Specify the OS version (for iOS Simulator) (default: $OS)"
    exit 1
}

# Parse command line flags and options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --platform) PLATFORM="$2"; shift ;;
        --app) APP="$2"; shift ;;
        --bundle-id) BUNDLE_ID="$2"; shift ;;
        --device) DEVICE="$2"; shift ;;
        --os) OS="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Check if required flags are provided
if [ -z "$APP" ]; then
    echo "Error: --app flag is required."
    usage
fi

if [ -z "$BUNDLE_ID" ]; then
    echo "Error: --bundle-id flag is required."
    usage
fi

# macOS build and run
if [ "$PLATFORM" = "macOS" ]; then
    echo "Building for macOS..."
    xcodebuild -scheme "$APP" -destination 'platform=macOS' build

    # Find app in derived data folder
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/$APP-*/Build/Products/Debug -name '*.app' | head -n 1)

    if [ -n "$APP_PATH" ]; then
        echo "Launching macOS app..."
        open "$APP_PATH"
    else
        echo "App not found in DerivedData."
    fi

# iOS Simulator build and run
elif [ "$PLATFORM" = "iOS Simulator" ]; then
    echo "Building for iOS Simulator..."
    xcodebuild -scheme "$APP" -destination "platform=$PLATFORM,name=$DEVICE,OS=$OS" build

    # Find app in derived data folder
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/$APP-*/Build/Products/Debug-iphonesimulator -name '*.app' | head -n 1)

    if [ -n "$APP_PATH" ]; then
        # Boot up simulator and install app
        open -a Simulator
        xcrun simctl boot "$DEVICE"
        xcrun simctl terminate booted "$BUNDLE_ID"
        xcrun simctl install booted "$APP_PATH"

        # Launch app
        echo "Launching iOS app on the simulator..."
        xcrun simctl launch booted "$BUNDLE_ID"
    else
        echo "App not found in DerivedData."
    fi
else
    echo "Invalid platform specified: $PLATFORM"
    usage
fi
