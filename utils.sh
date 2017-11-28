#!/bin/bash

PATH=/usr/libexec:$PATH

COMMAND="$1"
cd $(dirname "$0")

case "$COMMAND" in

    ######################################
    # Versioning
    ######################################
    "get-version")
        version_file="PreDemCocoa/Resources/Version.plist"
        echo "$(PlistBuddy -c "Print :Version" "$version_file")"
        exit 0
        ;; 

    "get-release-version")
        ./utils.sh get-version | cut -d v -f 2 | cut -d _ -f 1
        exit 0
        ;; 

    "set-version")
        dst_version="$2"
        sdk_version_file="PreDemCocoa/Resources/Version.plist"
        demo_version_files="PreDemCocoaDemo/PreDemObjcDemo/Info.plist PreDemCocoaDemo/PreDemSwiftDemo/Info.plist"
        git_commit=`git rev-parse --short HEAD`

        if [ -z "$dst_version" ]; then
            echo "You must specify a version."
            exit 1
        fi
            PlistBuddy -c "Set :Version $dst_version" "$sdk_version_file"
            PlistBuddy -c "Set :Build $git_commit" "$sdk_version_file"

        for version_file in $demo_version_files; do
            PlistBuddy -c "Set :CFBundleVersion $git_commit" "$version_file"
            PlistBuddy -c "Set :CFBundleShortVersionString $dst_version" "$version_file"
            echo "$version_file"
        done

        cd PreDemObjcDemo
        pod update --no-repo-update
        cd ..

        git add .
        git commit -m "bump version to $dst_version"
        git tag "$dst_version"

        exit 0
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
