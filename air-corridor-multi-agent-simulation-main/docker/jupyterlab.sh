#!/bin/bash

INSTALL_DIR=/opt/install
ENV_DIR=${INSTALL_DIR}/.venv

# if [ ! -d $ENV_DIR ]
# then
#     python3 -m venv $ENV_DIR
#     source $ENV_DIR/bin/activate
#     pip install -r ${INSTALL_DIR}/requirements.txt
#     deactivate
# fi
source $ENV_DIR/bin/activate
jupyter lab --allow-root --ip=0.0.0.0 --no-browser --port=8888

