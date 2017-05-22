#!/bin/sh

#  add-key.sh
#  PreSniffObjcDemo
#
#  Created by WangSiyu on 17/05/2017.
#  Copyright © 2017 pre-engineering. All rights reserved.

if [[ $TRAVIS_PULL_REQUEST == "false" && $TRAVIS_TAG =~ "^v.*\.rc[1-9]$" ]]; then
openssl aes-256-cbc -K $encrypted_6b87064fc261_key -iv $encrypted_6b87064fc261_iv -in scripts/profile/preengineeringPreSniffObjcDemo_InHouse.mobileprovision.enc -out scripts/profile/preengineeringPreSniffObjcDemo_InHouse.mobileprovision -d
openssl aes-256-cbc -K $encrypted_6b87064fc261_key -iv $encrypted_6b87064fc261_iv -in scripts/certs/dist.cer.enc -out scripts/certs/dist.cer -d
openssl aes-256-cbc -K $encrypted_6b87064fc261_key -iv $encrypted_6b87064fc261_iv -in scripts/certs/dist.p12.enc -out scripts/certs/dist.p12 -d
openssl aes-256-cbc -K $encrypted_6b87064fc261_key -iv $encrypted_6b87064fc261_iv -in scripts/certs/apple.cer.enc -out scripts/certs/apple.cer -d
exit $?
fi
