#!/bin/bash

# This script provides a simple interface for folks to use the docker install

browserimage=quay.io/blockstack/blockstack-browser:latest
browsercontainer=blockstack-api

build () {
  echo "Building blockstack docker image. This might take a minute..."
  docker build -t $browserimage .
}

start () {
  # Check for the blockstack-browser-* containers are running or stopped. 
  if [ "$(docker ps -q -f name=$browsercontainer)" ]; then
    echo "containers are already running"
    exit 1
  elif [ ! "$(docker ps -q -f name=$browsercontainer)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=$browsercontainer)" ]; then
      # cleanup old container if its still around
      echo "removing old container..."
      docker rm $browsercontainer
    fi
    
    # If there are no existing blockstack-browser-* containers, run them
    if [[ $(uname) == 'Linux' ]]; then
      docker run -d --name $browsercontainer-static -p 8888:8888 $browserimage blockstack-browser
      docker run -d --name $browsercontainer-cors -p 1337:1337 $browserimage blockstack-cors-proxy
    elif [[ $(uname) == 'Darwin' ]]; then
      docker run -d --name $browsercontainer-static -p 8888:8888 $browserimage blockstack-browser
      docker run -d --name $browsercontainer-cors -p 1337:1337 $browserimage blockstack-cors-proxy
    elif [[ $(uname) == 'Windows' ]]; then
      echo "Don't know if this works!!!"
      docker run -d --name $browsercontainer-static -p 8888:8888 $browserimage blockstack-browser
      docker run -d --name $browsercontainer-cors -p 1337:1337 $browserimage blockstack-cors-proxy
    fi
  fi
}

stop () {
  bc=$(docker ps -a -f name=$browsercontainer -q)
  if [ ! -z "$bc" ]; then
    echo "stopping the running blockstack-browser containers"
    docker stop $bc
    docker rm $bc
  fi
}

enter () {
  echo "entering docker container"
  docker exec -it $browsercontainer-static /bin/bash
}

logs () {
  echo "streaming logs for blockstack-api container"
  docker logs $browsercontainer-static -f
}

push () {
  echo "pushing build container up to quay.io..."
  docker push $browserimage
}

commands () {
  cat <<-EOF
bsdocker commands:
  start -> start the blockstack browser server
  stop -> stop the blockstack browser server
  logs -> access the logs from the blockstack browser server
  enter -> exec into the running docker container
EOF
}

case $1 in
  stop)
    stop
    ;;
  start)
    start
    ;;
  logs)
    logs
    ;;
  build)
    build 
    ;;
  enter)
    enter 
    ;;
  push)
    push
    ;;
  build)
    build
    ;;
  *)
    commands
    ;;
esac