#!/bin/sh

bundle install

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  bundle exec fastlane test
  exit $?
fi

if [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
  bundle exec fastlane beta
  exit $?
fi
