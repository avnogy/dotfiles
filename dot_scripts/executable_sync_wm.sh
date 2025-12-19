#!/bin/bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github

repos=("dwm" "slstatus" "slock")

for repo in "${repos[@]}"; do
    echo "Pulling updates for $repo..."

    cd "~/code/$repo" || { echo "Directory $repo not found!"; continue; }
    git pull mine master
    sudo make install
    cd -
done
