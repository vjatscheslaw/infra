#!/usr/bin/env bash

# check a user is root
if [[ $(id -u) ]]; then
  echo "Please, run the script as non-root. Actually, run it as a docker user"
  exit 1
fi

cd /home/$(whoami)

curl -fsSL https://get.docker.com/rootless | sh
export PATH=/home/$(whoami)/bin:$PATH
systemctl --user enable docker
echo "DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock" >> ~/.bashrc
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
#Simply a hint as to what the XDG_RUNTIME_DIR may be
#export XDG_RUNTIME_DIR=/run/usr/$UID
curl -L https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-`uname -m` -o bin/docker-compose
#This is how you run it
#docker-compose up 1> /home/dockermann/postgres.log 2> /home/dockermann/postgres.errors
