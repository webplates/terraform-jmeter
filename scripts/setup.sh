#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Please provide a DigitalOcean token"
    exit 1
fi

CONFIG="terraform.tfvars"

config(){
    if [ -f "$CONFIG" ]; then
        grep -q "^$1" $CONFIG && sed -i "s/^$1.*/$1 = \"$2\"/" $CONFIG || echo "$1 = \"$2\"" >> $CONFIG
    else
        echo "$1 = \"$2\"" > $CONFIG
    fi
}

if [ -d ".ssh" ]; then
    rm -rf .ssh
fi

mkdir -p .ssh
ssh-keygen -t rsa -b 4096 -f .ssh/jmeter -q -N ""

config "do_token" $1
