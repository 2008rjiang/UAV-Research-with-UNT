#!/bin/bash

if [ -z "$1" ]
then
	CMD="bash"
else
	CMD="$1"
fi
SECRETS=`realpath ~/.secrets`

if [ -n "$SECRETS" ]
then
	SECRETS_VOLUME="-v $SECRETS:/opt/secrets"
else
	SECRETS_VOLUME=""
fi 
docker run -it -p 8888:8888 \
	-v `realpath ..`:/opt/work $SECRETS_VOLUME \
	aircorridor "$CMD"
