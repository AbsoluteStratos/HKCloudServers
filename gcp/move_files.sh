#!/bin/bash

if [[ -z "$1" ]]
    then
    echo -n "Enter GCP username: " 
    read username
else
    username=$1
fi

if [[ -z "$2" ]] 
then
    echo -n "Enter GCP external IP: " 
    read externalip
else
    externalip=$2
fi

rsync -rv \
    --stats \
    --progress \
    -e "ssh -i \"$HOME/.ssh/gcp\"" \
    --exclude terraform \
    ./* ${username}@${externalip}:/home/${username}/hollowknight