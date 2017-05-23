#!/bin/bash

bundle install

reg_rc="^v[0-9]+\.[0-9]+\.[0-9]+-rc[0-9]*$"
reg_release="^v[0-9]+\.[0-9]+\.[0-9]+$"

# rc
if [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_TAG =~ $reg_rc ]]; then
  bundle exec fastlane beta
  exit $?
# release
elif [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_TAG =~ $reg_release ]]; then
  bundle exec fastlane release
  exit $?
# commit or pr
else
  bundle exec fastlane test
  exit $?
fi
