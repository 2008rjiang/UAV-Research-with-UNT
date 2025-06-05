#!/bin/bash

DIR=`dirname $0`
pushd $DIR
docker build -t aircorridor .
popd

