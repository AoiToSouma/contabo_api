#!/bin/bash

# Set Colour Vars
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color


source ./profile.conf

FUNC_INIT(){
    IP_ADDRESS=$(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
    echo -e "${GREEN}Get ACCESS_TOKEN...${NC}"
    RESULT=$(curl -s -d "client_id=$CLIENT_ID" -d "client_secret=$CLIENT_SECRET" --data-urlencode "username=$API_USER" --data-urlencode "password=$API_PASSWORD" -d 'grant_type=password' 'https://auth.contabo.com/auth/realms/contabo/protocol/openid-connect/token')
    ACCESS_TOKEN=$(echo $RESULT | jq -r '.access_token')
    if [ "$ACCESS_TOKEN" = "null" ]; then
        echo -e "${RED}$(echo $RESULT | jq '.error_description')${NC}"
        exit 0
    fi
    # get list of your instances
    echo -e "${GREEN}Get your instances...${NC}"
    UUID=$(uuidgen)
    INSTANCE_ALL=$(curl -s -X GET 'https://api.contabo.com/v1/compute/instances' -H 'Content-Type: application/json' -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "x-request-id: ${UUID}" -H 'x-trace-id: 123213')
    RESULT=$(echo $INSTANCE_ALL | jq -r '.statusCode')
    if [ "$RESULT" != "null" ]; then
        ERROR=$(echo $INSTANCE_ALL | jq '.statusCode')" : "$(echo $INSTANCE_ALL | jq -r '.message')
        echo -e "${RED}Failed to obtain instance.(${ERROR})${NC}"
        exit 0
    fi
    MY_INSTANCE=$(echo $INSTANCE_ALL | jq --arg arg1 "$IP_ADDRESS" '.data[] | select(.ipConfig.v4.ip == $arg1)')
    INSTANCE_ID=$(echo $MY_INSTANCE | jq '.instanceId')
}

FUNC_LIST_SNAPSHOT(){
    FUNC_INIT;
    # get list of snapshot
    echo -e "${GREEN}Get list of snapshot...${NC}"
    UUID=$(uuidgen)
    SNAPSHOT=$(curl -s -X GET "https://api.contabo.com/v1/compute/instances/${INSTANCE_ID}/snapshots" -H 'Content-Type: application/json' -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "x-request-id: ${UUID}" -H 'x-trace-id: 123213')
    RESULT=$(echo $SNAPSHOT | jq -r '.statusCode')
    if [ "$RESULT" != "null" ]; then
        ERROR=$(echo $SNAPSHOT | jq '.statusCode')" : "$(echo $SNAPSHOT | jq -r '.message')
        echo -e "${RED}Failed to obtain instance.(${ERROR})${NC}"
        exit 0
    fi
    SNAPSHOT_LIST=$(echo $SNAPSHOT | jq '.data[]')
}

FUNC_INFO(){
    FUNC_LIST_SNAPSHOT;

    echo -e "${GREEN}"
    echo "[VPS Information]----------------------------------"
    echo "instanceId     : $(echo $MY_INSTANCE | jq -r '.instanceId')"
    echo "vHostId        : $(echo $MY_INSTANCE | jq -r '.vHostId')"
    echo "productName    : $(echo $MY_INSTANCE | jq -r '.productName')"
    echo "dataCenter     : $(echo $MY_INSTANCE | jq -r '.dataCenter')"
    echo "region         : $(echo $MY_INSTANCE | jq -r '.region')"
    echo "regionName     : $(echo $MY_INSTANCE | jq -r '.regionName')"
    echo "ip             : $(echo $MY_INSTANCE | jq -r '.ipConfig.v4.ip')"
    echo "cpuCores       : $(echo $MY_INSTANCE | jq -r '.cpuCores')"
    echo "ramMb          : $(echo $MY_INSTANCE | jq -r '.ramMb')"
    echo "diskMb         : $(echo $MY_INSTANCE | jq -r '.diskMb')"
    echo "createdDate    : $(echo $MY_INSTANCE | jq -r '.createdDate')"
    echo "status         : $(echo $MY_INSTANCE | jq -r '.status')"
    echo "[Snapshot]-----------------------------------------"
    echo "snapshotId     : $(echo $SNAPSHOT_LIST | jq -r '.snapshotId')"
    echo "name           : $(echo $SNAPSHOT_LIST | jq -r '.name')"
    echo "description    : $(echo $SNAPSHOT_LIST | jq -r '.description')"
    echo "createdDate    : $(echo $SNAPSHOT_LIST | jq -r '.createdDate')"
    echo "autoDeleteDate : $(echo $SNAPSHOT_LIST | jq -r '.autoDeleteDate')"
    echo "---------------------------------------------------"
    echo -e "${NC}"
}

FUNC_GET_SNAPSHOT(){
    FUNC_INIT;

    # Create a new instance snapshot
    read -p "Input Snapshot Name : " ssname
    read -p "Input Description : " desc
    if [ "$desc" = "" ]; then
        desc="Created by ContaboApi"
    fi
    data=$(jq --arg arg1 "$ssname" --arg arg2 "$desc" -n '.name=$arg1 | .description=$arg2')
    UUID=$(uuidgen)
    SNAPSHOT=$(curl -s -X POST "https://api.contabo.com/v1/compute/instances/${INSTANCE_ID}/snapshots" -H 'Content-Type: application/json' -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "x-request-id: ${UUID}" -H 'x-trace-id: 123213' -d "$data")
    RESULT=$(echo $SNAPSHOT | jq -r '.statusCode')
    if [ "$RESULT" != "null" ]; then
        ERROR=$(echo $SNAPSHOT | jq '.statusCode')" : "$(echo $SNAPSHOT | jq -r '.message')
        echo -e "${RED}Failed to create snapshot.(${ERROR})${NC}"
        exit 0
    fi
    CREATED=$(echo $SNAPSHOT | jq '.data[]')
    echo -e "${GREEN}"
    echo "[Created Snapshot]---------------------------------"
    echo "snapshotId     : $(echo $CREATED | jq -r '.snapshotId')"
    echo "name           : $(echo $CREATED | jq -r '.name')"
    echo "description    : $(echo $CREATED | jq -r '.description')"
    echo "createdDate    : $(echo $CREATED | jq -r '.createdDate')"
    echo "autoDeleteDate : $(echo $CREATED | jq -r '.autoDeleteDate')"
    echo "---------------------------------------------------"
    echo -e "${NC}"
}

FUNC_DEL_SNAPSHOT(){
    # Check snapshot
    FUNC_LIST_SNAPSHOT;
    if [ "${SNAPSHOT_LIST}" != "" ]; then
        SNAPSHOT_ID=$(echo $SNAPSHOT_LIST | jq -r '.snapshotId')
        echo -e "${GREEN}"
        echo "[Current Snapshot]---------------------------------"
        echo "snapshotId     : ${SNAPSHOT_ID}"
        echo "name           : $(echo $SNAPSHOT_LIST | jq -r '.name')"
        echo "description    : $(echo $SNAPSHOT_LIST | jq -r '.description')"
        echo "createdDate    : $(echo $SNAPSHOT_LIST | jq -r '.createdDate')"
        echo "autoDeleteDate : $(echo $SNAPSHOT_LIST | jq -r '.autoDeleteDate')"
        echo "---------------------------------------------------"
        echo -e "${RED}"
        while true; do
            read -p "Are you sure you want to delete the current snapshot? (Y/N) " _input
            case $_input in
                [Yy][Ee][Ss]|[Yy]* ) 
                    UUID=$(uuidgen)
                    echo -e "${NC}"
                    SNAPSHOT=$(curl -s -X DELETE "https://api.contabo.com/v1/compute/instances/${INSTANCE_ID}/snapshots/${SNAPSHOT_ID}" -H 'Content-Type: application/json' -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "x-request-id: ${UUID}" -H 'x-trace-id: 123213')
                    if [ "$SNAPSHOT" != "" ]; then
                        ERROR=$(echo $SNAPSHOT | jq '.statusCode')" : "$(echo $SNAPSHOT | jq -r '.message')
                        echo -e "${RED}Failed to delete snapshot.(${ERROR})${NC}"
                        exit 0
                    fi
                    echo -e "${GREEN}Snapshot deleted.${NC}"
                    break
                    ;;
                [Nn][Oo]|[Nn]* ) 
                    echo -e "${GREEN}Snapshot deletion canceled.${NC}"
                    break
                    ;;
                * ) echo "Please answer (y)es or (n)o.";;
            esac
        done
        echo -e "${NC}"
    else
        echo -e "${GREEN}There are no snapshots.${NC}"
    fi
}

case "$1" in
    status)
        FUNC_INFO
        ;;
    snapshot)
        case "$2" in
            create)
                FUNC_GET_SNAPSHOT
                ;;
            delete)
                FUNC_DEL_SNAPSHOT
                ;;
            *)
                echo
                echo "Usage: $0 $1 {function}"
                echo
                echo "    example: " $0 $1 create""
                echo
                echo "where {function} is one of the following;"
                echo
                echo "    create       == Create a new snapshot of the logged in VPS."
                echo "    delete       == Delete the snapshot of the logged in VPS."
                echo
        esac
        ;;
    *)
        echo
        echo
        echo "Usage: $0 {function}"
        echo
        echo "    example: " $0 status""
        echo
        echo "where {function} is one of the following;"
        echo
        echo "    status                 == Display status about logged in VPS."
        echo "    snapshot create        == Create a new snapshot of the logged in VPS."
        echo "    snapshot delete        == Delete the snapshot of the logged in VPS."
        echo

esac
