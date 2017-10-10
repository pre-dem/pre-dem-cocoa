#!/bin/sh

#  add-key.sh
#  PreDemObjcDemo
#
#  Created by WangSiyu on 17/05/2017.
#  Copyright © 2017 pre-engineering. All rights reserved.

# Create a custom keychain
security create-keychain -p travis ios-build.keychain

# avoid been asked to enter password while signing product
# see https://github.com/fastlane/fastlane/issues/7104
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k travis ios-build.keychain

# Make the custom keychain default, so xcodebuild will use it for signing
security default-keychain -s ios-build.keychain

# Unlock the keychain
security unlock-keychain -p travis ios-build.keychain

# Set keychain timeout to 1 hour for long builds
# see http://www.egeek.me/2013/02/23/jenkins-and-xcode-user-interaction-is-not-allowed/
security set-keychain-settings -t 3600 -l ~/Library/Keychains/ios-build.keychain

# Add certificates to keychain and allow codesign to access them
security import ./encrypt/apple.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
security import ./encrypt/dist.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
security import ./encrypt/dist.p12 -k ~/Library/Keychains/ios-build.keychain -P $KEY_PASSWORD -T /usr/bin/codesign

# Put the provisioning profile in place
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp "./encrypt/preengineeringPreDemObjcDemo_InHouse.mobileprovision" ~/Library/MobileDevice/Provisioning\ Profiles/
exit $?
