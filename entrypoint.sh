#!/bin/bash

mkdir -p ~/.ssh
chown -R root:root ~/.ssh
chmod -R 0700 ~/.ssh
cp -ip /run/secrets/ssh_key ~/.ssh/id_rsa
chmod -R 0600 ~/.ssh
bash
exec "$@"