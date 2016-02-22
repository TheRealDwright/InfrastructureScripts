#!/usr/bin/env bash

mkdir -p ~/.ssh
cp id_rsa ~/.ssh/
cp ./*.pem ~/.ssh/
chmod 400 ~/.ssh/*.pem
chmod 400 ~/.ssh/id_rsa
