#!/usr/bin/env bash

#setup .pem files.

mkdir -p ~/.ssh
cp ./local_config/pem/id_rsa ~/.ssh/
cp ./local_config/pem/*.pem ~/.ssh/
chmod 400 ~/.ssh/*.pem
chmod 400 ~/.ssh/id_rsa
