#!/usr/bin/env bash

printf "AWS_NAME: %s" "${3:-$1-$2}"

ansible-playbook aws-deploy.yml --extra-vars "target_env=$1 app_name=$2 aws_name=${3:-$1-$2}" -i ec2.py \
 --private-key=~/.ssh/ansible.deploy.pem --vault-password-file .vault_pass.txt
