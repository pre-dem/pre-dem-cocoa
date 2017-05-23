#!/bin/sh

bundle install

env

# rc
if [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_TAG =~ "^v.*\.rc[1-9]$" ]]; then
  bundle exec fastlane beta
  exit $?
# release
elif [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_TAG =~ "^v.*$" ]]; then
  bundle exec fastlane release
  exit $?
# commit or pr
else
  bundle exec fastlane test
  exit $?
fi
