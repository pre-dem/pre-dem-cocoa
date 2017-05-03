#!/bin/sh

gem install slather
gem update fastlane

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  fastlane test
  exit $?
fi
