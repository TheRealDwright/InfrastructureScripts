#!/usr/bin/env bash

#setup boto profiles

mkdir -p ~/.aws
cp ./local_config/aws/credentials ~/.aws/
cp ./local_config/aws/config ~/.aws/
