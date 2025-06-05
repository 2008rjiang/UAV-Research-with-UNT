#!/bin/bash

INSTALL_DIR=/opt/install
ENV_DIR=${INSTALL_DIR}/.venv

python3 -m venv $ENV_DIR
source $ENV_DIR/bin/activate
pip install -r ${INSTALL_DIR}/requirements.txt
deactivate




