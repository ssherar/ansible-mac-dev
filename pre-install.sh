#!/bin/bash

xcode-select --install

python3 -m pip install --user pipx
exec $(python3 -m pipx ensurepath)
pipx install --include-deps ansible
pipx inject ansible paramiko
ansible-galaxy install -r requirements.yml