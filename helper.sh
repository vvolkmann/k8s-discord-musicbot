#!/bin/sh

#$1 = START/STOP
#$2 = bot-name

# Variables
#BOT_TOKEN="bot-token-here"
#BOT_OWNER="owner-id-here"
#BOT_PREFIX="-"
#BOT_UPDATES="true"

#K8S_BOTNAME="musicbot"
#K8S_NAMESPACE="namespace"

. ./secrets.sh


if [ "$1" = "START" ]; then
    echo "Applying resources"
    # Updates config with values from variables section
    cp ./config.txt ./config.cfg
    #sed -i "s/^token.*$/token = $BOT_TOKEN/g" ./config.cfg
    #sed -i "s/^owner.*$/owner = $BOT_OWNER/g" ./config.cfg
    sed -i "s/^updatealerts.*$/updatealerts = $BOT_UPDATES/g" ./config.cfg
    sed -i "s/^prefix = .*$/prefix = \"$BOT_PREFIX\"/g" ./config.cfg

    cp ./musicbot.yaml ./musicbot.yml
    sed -i "s/musicbot-secrets-name/musicbot-secrets-$K8S_BOTNAME/g" ./musicbot.yml
    sed -i "s/TOKENSTRING/$BOT_TOKEN/g" ./musicbot.yml
    sed -i "s/OWNERSTRING/$BOT_OWNER/g" ./musicbot.yml
    
    sed -i "s/pv-hostpath-name/pv-hostpath-$K8S_BOTNAME/g" ./musicbot.yml
    sed -i "s/pvc-hostpath-name/pvc-hostpath-$K8S_BOTNAME/g" ./musicbot.yml
    
    sed -i "s/musicbot-name/$K8S_BOTNAME/g" ./musicbot.yml
    sed -i "s/bot-data-name/bot-data-$K8S_BOTNAME/g" ./musicbot.yml
    sed -i "s/bot-config-name/bot-config-$K8S_BOTNAME/g" ./musicbot.yml

    # Creates the config secret with the above provided values
    kubectl -n $K8S_NAMESPACE create secret generic bot-config-$K8S_BOTNAME --from-file=./config.cfg
    # Creates the bot
    kubectl -n $K8S_NAMESPACE apply -f ./musicbot.yml
    
    echo "Done."


elif [ "$1" = "STOP" ]; then
    if [ -z "$2" ]; then
        echo "Please inform which to delete. Example: xxx-musicbot"
    else
        echo "Deleting resources"
        kubectl delete -n $K8S_NAMESPACE $(kubectl -n $K8S_NAMESPACE get deploy,pvc,pv,secrets | grep $2 | awk '{ print $1 }')
        echo "Done."
    fi

    # Remove temp files
    rm config.cfg musicbot.yml


else
    #DEBUG
    echo "Debugging..."
    #kubectl run -i --tty alpine --image=alpine -- sh
fi