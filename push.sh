#!/bin/bash

setup_git() {
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "Travis CI"
}

commit_files() {
    git clone https://${GH_TOKEN}@github.com/antonchen/passwall-rules.git ~/passwall-rules > /dev/null 2>&1
    cd ~/passwall-rules
    test -d rules && git rm -f rules/*
    cp -rf $HOME/rules .
    git add .
    git commit -m "Travis build: $(date +%F)"
}

upload_files() {
    git push origin master
}

setup_git
commit_files
upload_files
