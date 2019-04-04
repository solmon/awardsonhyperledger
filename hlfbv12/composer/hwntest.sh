#!/bin/bash

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  hwntest.sh -m test [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>] [-i <imagetag>]"
  echo "  hwn.sh -h|--help (print this message)"
  echo "    -m <mode> - one of 'test'"
  echo "      - 'test' - bring up the network with test existing network"
  echo "    -c <channel name> - channel name to use (defaults to \"mychannel\")"
  echo "    -t <timeout> - CLI timeout duration in microseconds (defaults to 10000)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -f <docker-compose-file> - specify which docker-compose file use (defaults to docker-compose-cli.yaml)"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -i <imagetag> - pass the image tag to launch the network using the tag: 1.0.1, 1.0.2, 1.0.3, 1.0.4 (defaults to latest)"
}

function testme () {
  # generate artifacts if they don't exist
  if [ "${IF_COUCHDB}" == "couchdb" ]; then  
      IMAGE_TAG=$IMAGETAG CHANNEL_NAME=$CHANNEL_NAME TIMEOUT=$CLI_TIMEOUT DELAY=$CLI_DELAY docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH up -d 2>&1
  else
      echo "Emiting my docker compose command"
      echo ${IMAGE_TAG=$IMAGETAG CHANNEL_NAME=$CHANNEL_NAME TIMEOUT=$CLI_TIMEOUT DELAY=$CLI_DELAY docker-compose -f $COMPOSE_FILE up -d 2>&1}
      IMAGE_TAG=$IMAGETAG CHANNEL_NAME=$CHANNEL_NAME TIMEOUT=$CLI_TIMEOUT DELAY=$CLI_DELAY docker-compose -f $COMPOSE_FILE up -d 2>&1
  fi
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    docker logs -f cli
    exit 1
  fi
  docker logs -f cli
}

function networkDown () {
  docker-compose -f $COMPOSE_FILE down --volumes
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH down --volumes   
}


# Ask user for confirmation to proceed
function askProceed () {
  read -p "Continue (y/n)? " ans
  case "$ans" in
    y|Y )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
#default for delay
CLI_DELAY=10
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# use this as the default docker-compose yaml definition
COMPOSE_FILE=docker-compose-cli-test.yaml
#
COMPOSE_FILE_COUCH=docker-compose-couch.yaml
# default image tag
IMAGETAG="x86_64-1.1.0"
# Parse commandline args
while getopts "h?m:c:t:d:f:s:i:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    m)  MODE=$OPTARG
    ;;
    c)  CHANNEL_NAME=$OPTARG
    ;;
    t)  CLI_TIMEOUT=$OPTARG
    ;;
    d)  CLI_DELAY=$OPTARG
    ;;
    f)  COMPOSE_FILE=$OPTARG
    ;;
    s)  IF_COUCHDB=$OPTARG
    ;;
    i)  IMAGETAG=`uname -m`"-"$OPTARG
    ;;
  esac
done

# Determine whether starting, stopping, restarting or generating for announce
if [ "$MODE" == "test" ]; then
  EXPMODE="Starting"  
  elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
else
  printHelp
  exit 1
fi

# Announce what was requested

  if [ "${IF_COUCHDB}" == "couchdb" ]; then
        echo
        echo "${EXPMODE} with channel '${CHANNEL_NAME}' and CLI timeout of '${CLI_TIMEOUT}' using database '${IF_COUCHDB}'"
  else
        echo "${EXPMODE} with channel '${CHANNEL_NAME}' and CLI timeout of '${CLI_TIMEOUT}'"
  fi
# ask for confirmation to proceed
askProceed

#Create the network using docker compose
if [ "${MODE}" == "test" ]; then
  testme
  elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
else
  printHelp
  exit 1
fi
