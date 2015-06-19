#!/bin/bash -eux

apt-add-repository -y ppa:ansible/ansible
apt-get -y update
apt-get -y install ansible
