#!/bin/bash

##
## Configuration
##

WORKDIR="bundle"
BUNDLEDIR="burp-bundle"
CONFIG_TEMPLATE="UserConfigPro-template.json"
CONFIG_TEMP="UserConfigPro.tmp"
CONFIG_JSON="UserConfigPro.json"
EXTENSION_TYPES=(
    "thereisnotypezero"
    "java"
    "python"
    "ruby"
    )
## List of BAPPS to set to enabled
ENABLED_BAPPS=(
    "Active Scan++" 
    "Hackvertor"
    "Piper"
    "Turbo Intruder"
    "Collaborator Everywhere"
    "Backslash Powered Scanner"
    "Content Type Converter"
    "Additional Scanner Checks"
    "Software Vulnerability Scanner"
    "Retire.js"
    "Logger++"
    )
## Eyecandy
MARKER="$(tput bold)[+]$(tput sgr0)"

## Place to works with the bundle to not mess with the repo
REPO_DIR=$(pwd)
cd ${WORKDIR}

## Use a specific version of Burp Suite
# BURP_VERSION="2023.10.3.4"
## OR download the latest version of Burp Suite
BURP_VERSION=$(curl -s https://portswigger.net/burp/releases |grep -E 'Professional / Community 202[3-9]{1}.[0-9]{1,2}.[0-9]{1,2}.[0-9]{1,2}' | head -n 1 | cut -d '/' -f 2 | sed -e 's/^ Community //' -e 's/<$//')
echo "${MARKER} Using Burp Suite $(tput bold)${BURP_VERSION}$(tput sgr0)"

# Create a directory to store the bundle
mkdir -p ${BUNDLEDIR} 2>/dev/null
cd ${BUNDLEDIR}

## Download burp installer and/or standalone
if [ ! -f "burpsuite_pro.exe" ]; then
    echo "${MARKER} Downloading Burp Suite $(tput bold)${BURP_VERSION}$(tput sgr0)."
    curl -s -o burpsuite_pro.exe "https://portswigger-cdn.net/burp/releases/download?product=pro&version=${BURP_VERSION}&type=WindowsX64"
fi
## if [ ! -f "jython-standalone.jar" ]; then
##     echo "${MARKER} Downloading Burp Suite $(tput bold)${BURP_VERSION}$(tput sgr0)."
##     curl -s -o burpsuite_pro.jar  "https://portswigger-cdn.net/burp/releases/download?product=pro&version=${BURP_VERSION}&type=jar"
## fi

if [ ! -f "jython-standalone.jar" ]; then
    echo "${MARKER} Downloading Jython."
    curl -s -o jython-standalone.jar https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.3/jython-standalone-2.7.3.jar 
fi


## Download all BAPPs
echo "${MARKER} Downloading BAPPs."
BAPP_LIST=$(curl -s "https://portswigger.net/bappstore" | grep -E '[a-f0-9]{32}' | cut -d '"' -f 4)
BAPP_COUNT=$(echo $BAPP_LIST | wc -w| tr -d ' ')
I=1
for BAPP in $BAPP_LIST; do
    ## echo "Accessing [${I}/${BAPP_COUNT}] ${BAPP}"
    BAPP_FILE=$(curl -s "https://portswigger.net${BAPP}" | grep -E '[a-f0-9]{32}/[0-9]{1,2}' | cut -d '"' -f 4)
    BAPP_HASH=$(echo ${BAPP} | cut -d '/' -f 3)
    if [ ! -f "${BAPP_HASH}.bapp" ]; then
        echo "$(tput bold)[${I}/${BAPP_COUNT}]$(tput sgr0) Downloading ${BAPP_FILE}"
        curl -s -O -J "${BAPP_FILE}"
    else
        echo "$(tput bold)[${I}/${BAPP_COUNT}]$(tput sgr0) ${BAPP_HASH}.bapp already downloaded."
    fi
    I=$((I+1))
done


## Extract all BAPPs
echo "${MARKER} Extracting BAPPs."
BAPP_FILES=$(ls *.bapp)
BAPP_COUNT=$(echo $BAPP_FILES | wc -w| tr -d ' ')
I=1
for BAPP_ARCHIVE in ${BAPP_FILES}; do
    BAPP_DIR=$(echo ${BAPP_ARCHIVE} | cut -d '.' -f 1)
    echo "$(tput bold)[${I}/${BAPP_COUNT}]$(tput sgr0) Extracting ${BAPP_DIR}"
    unzip -q "${BAPP_DIR}.bapp" -d "${BAPP_DIR}"
    I=$((I+1))
done

# # Start with a blank copy of the template to add BAPPs to
cp ${REPO_DIR}/${CONFIG_TEMPLATE} ${CONFIG_JSON}

## Extract information from BAPP manifest
echo "${MARKER} Adding BAPPs to config."
BAPP_DIRS=$(ls -d1 */| tr -d '\/')
BAPP_DIR_COUNT=$(echo $BAPP_DIRS | wc -w| tr -d ' ')
I=1
for BAPP_UID in ${BAPP_DIRS}; do
    # Remember that some manifest files use windows encoding, so beware of the nasty ^M
    EXTENSION_NAME=$(cat ${BAPP_UID}/BappManifest.bmf | grep '^Name:' | cut -d ' ' -f 2- | tr -d '\r')
    EXTENSION_VERSION=$(cat ${BAPP_UID}/BappManifest.bmf | grep 'SerialVersion:' | cut -d ' ' -f 2 | tr -d '\r')
    EXTENSION_ENTRYPOINT=$(cat ${BAPP_UID}/BappManifest.bmf | grep 'EntryPoint:' | cut -d ' ' -f 2- | sed 's/\//\\/g'| tr -d '\r') # escape backslashes for windows
    EXTENSION_TYPE=$(cat ${BAPP_UID}/BappManifest.bmf | grep 'ExtensionType:' | cut -d ' ' -f 2 | tr -d '\r')
    #echo "BAPP: ${BAPP_UID} - EXTENSION_NAME: ${EXTENSION_NAME} - EXTENSION_VERSION: ${EXTENSION_VERSION} - EXTENSION_ENTRYPOINT: ${EXTENSION_ENTRYPOINT} - EXTENSION_TYPE: ${EXTENSION_TYPE}/${EXTENSION_TYPES[$EXTENSION_TYPE]}"
    echo "$(tput bold)[${I}/${BAPP_DIR_COUNT}]$(tput sgr0) Adding '${EXTENSION_NAME}' to config."
    # add the BAPPs to config as disabled
    # add all to a temporary json array which will be appended the template later
    jq -r \
    '.user_options.extender.extensions[.user_options.extender.extensions| length] += {
    "bapp_serial_version":$ARGS.positional[1],
    "bapp_uuid":$ARGS.positional[0],
    "errors":"ui",
    "extension_file": ("bapps\\" + $ARGS.positional[0] + "\\" + $ARGS.positional[2]),
    "extension_type":$ARGS.positional[4],
    "loaded":false,
    "name": $ARGS.positional[3],
    "output":"ui"}' \
    ${CONFIG_JSON} \
    --args "${BAPP_UID}" ${EXTENSION_VERSION} "${EXTENSION_ENTRYPOINT}" "${EXTENSION_NAME}" "${EXTENSION_TYPES[$EXTENSION_TYPE]}" > ${CONFIG_TEMP} # save to a temp not to owerwrite the original
    # replace the original with the temp
    mv ${CONFIG_TEMP} ${CONFIG_JSON}
    I=$((I+1))
done

## Set the "loaded" flag for chosen BAPPs
echo "${MARKER} Enabling BAPPs."
for ((i = 0; i < ${#ENABLED_BAPPS[@]}; i++)); do
    echo "$(tput bold)[${i}/${#ENABLED_BAPPS[@]}$(tput sgr0) Enabling '${ENABLED_BAPPS[$i]}' to config."
    jq -r '(.user_options.extender.extensions[] | select(.name == $ENABLE).loaded) |= true' \
    ${CONFIG_JSON} \
    --arg ENABLE "${ENABLED_BAPPS[$i]}" > ${CONFIG_TEMP} 
    # save to a temp not to owerwrite the original and replace the original with the temp
    mv ${CONFIG_TEMP} ${CONFIG_JSON}
done

# Zip the bundle
cd ..
echo "${MARKER} Creating archive."
zip -r burp-bundle.zip "${BUNDLEDIR}" -x "*.DS_Store" "*.bapp"
echo "${MARKER} Created archive burp-bundle.zip."
ls -lh burp-bundle.zip
# End