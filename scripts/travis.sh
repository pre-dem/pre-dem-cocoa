#!/bin/bash

bundle install

reg_alpha="^v[0-9]+\.[0-9]+\.[0-9]+_alpha[0-9]*$"
reg_release="^v[0-9]+\.[0-9]+\.[0-9]+$"

prepare_sign_env()
{
  openssl aes-256-cbc -K $encrypted_321b310503f8_key -iv $encrypted_321b310503f8_iv -in encrypt/dist.p12.enc -out encrypt/dist.p12 -d
  openssl aes-256-cbc -K $encrypted_321b310503f8_key -iv $encrypted_321b310503f8_iv -in encrypt/dist.cer.enc -out encrypt/dist.cer -d
  openssl aes-256-cbc -K $encrypted_321b310503f8_key -iv $encrypted_321b310503f8_iv -in encrypt/apple.cer.enc -out encrypt/apple.cer -d
  openssl aes-256-cbc -K $encrypted_321b310503f8_key -iv $encrypted_321b310503f8_iv -in encrypt/preengineeringPreDemObjcDemo_InHouse.mobileprovision.enc -out encrypt/preengineeringPreDemObjcDemo_InHouse.mobileprovision -d
  ./scripts/add-key.sh
}

# alpha
if [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_TAG =~ $reg_alpha ]]; then
  prepare_sign_env
  bundle exec fastlane beta
  exit $?
# release
elif [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_TAG =~ $reg_release ]]; then
  prepare_sign_env
  bundle exec fastlane release
  exit $?
# commit or pr
else
  bundle exec fastlane test
  exit $?
fi
