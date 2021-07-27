#!/bin/bash

# Fail out on error when starting the container
set -e

omBuilderName="ombuilder"

readonly numargs=$#
args="${@}"
if [ $numargs -lt 1 ]; then
   args="/bin/bash"
fi

# Disable ctrl-z so users cannot stop abruptly
# trap ctrl-c to stop the container
trap "" SIGTSTP
trap user_exit INT
trap user_exit SIGINT

function user_exit() {
   docker rm -f $containerName > /dev/null
   exit 0
}

readonly REPO_ROOT=$(readlink -e $PWD)
readonly DEVICE_NAME=$(basename "$PWD")

containerName="omBuilder1"

docker volume create userhome > /dev/null

docker run -i -d --rm \
   --env LOCAL_USER_ID=$(id -u) \
   --workdir=/src\
   --name $containerName \
   --hostname $containerName \
   -v userhome:/home/user:Z \
   -v ${REPO_ROOT}:/src:Z \
   $omBuilderName > /dev/null

# Don't exit on error here - the container needs to be stopped regardless
#   of the result of executing the commands
set +e

docker exec --user $(id -u) --env HOME=/home/user  -it $containerName sh -c "$args"
result=$?

docker rm -f $containerName > /dev/null

exit ${result}
