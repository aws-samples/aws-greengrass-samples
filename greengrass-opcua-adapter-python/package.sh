#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# package.sh
# Script to package up the current directory as a ZIP file that can be uploaded
# to an S3 bucket as the source for an AWS Lambda function 
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# These values will change between folders.
# -----------------------------------------------------------------------------
LAMBDA_NAME="python_opcua_adapter"
LAMBDA_FILE="lambda_function.py"

# -----------------------------------------------------------------------------
# Main body
# You shouldn't need to edit anything below this area
# -----------------------------------------------------------------------------
basename=`basename $0`

PYTHON=`which python`
PIP=`which pip`

TEMP_PKG_DIR="lib"

ZIP=`which zip`
ZIP_ARGS="-r"
ADDITIONAL_FOLDERS="greengrass_common greengrasssdk greengrass_ipc_python_sdk"

for folder in ${ADDITIONAL_FOLDERS}; do
    if [ ! -d ${folder} ]; then
        echo "Folder \"${folder}\" does not exist. Make sure you have the Greengrass SDK downloaded." >& 2
        exit 1
    fi
done

if [ ! -d ${TEMP_PKG_DIR} ]; then
    mkdir ${TEMP_PKG_DIR}
fi

# Make sure that python is on the path.
if [ -f "${PYTHON}" ]; then
    # Now verify that pip is installed, so you can install the
    # requirements
    if [ -f "${PIP}" ]; then
        ${PIP} install -r requirements.txt -t ${TEMP_PKG_DIR} >/dev/null 2>&1
        # Copy the files from the additional folders to the temporary lib folder
        tar cf - ${ADDITIONAL_FOLDERS} | tar -C ${TEMP_PKG_DIR} -xf - 
        cp ${LAMBDA_FILE} ${TEMP_PKG_DIR}

        # Now zip up both the lambda and the lib
        (cd ${TEMP_PKG_DIR} && ${ZIP} ${ZIP_ARGS} "../${LAMBDA_NAME}.zip" ${ADDITIONAL_FOLDERS} *) >/dev/null 2>&1

        # Remove the lib directory
        if [ $? -eq 0 ]; then
            rm -rf ${TEMP_PKG_DIR} >/dev/null 2>&1
        fi
    else
        echo "${basename}: pip package manager not found!" >& 2
        exit 1
    fi
else
    echo "${basename}: No python interpretor found!" >& 2
    exit 1
fi

exit 0
