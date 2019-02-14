#!/bin/bash

# HELK script: elasticsearch-entrypoint.sh
# HELK script description: sets elasticsearch configs and starts elasticsearch
# HELK build Stage: Alpha
# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# *********** Setting ES_JAVA_OPTS ***************
if [[ -z "$ES_JAVA_OPTS" ]]; then
		# Check using more accurate MB
    AVAILABLE_MEMORY=$(awk '/MemAvailable/{printf "%.f", $2/1024}' /proc/meminfo)
    if [ $AVAILABLE_MEMORY -ge 1000 -a $AVAILABLE_MEMORY -le 7999 ]; then
      ES_MEMORY=1
    elif [ $AVAILABLE_MEMORY -ge 8000 -a $AVAILABLE_MEMORY -le 12999 ]; then
      ES_MEMORY=2
    elif [ $AVAILABLE_MEMORY -ge 13000 -a $AVAILABLE_MEMORY -le 16000 ]; then
      ES_MEMORY=4
    else
      # Using divide by 2 here, to use GB instead of MB -- because plenty of RAM now
      ES_MEMORY='$(${AVAILABLE_MEMORY}/2}'
      if [ ES_MEMORY -gt 31000 ]; then
        ES_MEMORY=31
      fi
    fi
    export ES_JAVA_OPTS="-Xms${ES_MEMORY}g -Xmx${ES_MEMORY}g -XX:-UseConcMarkSweepGC -XX:-UseCMSInitiatingOccupancyOnly -XX:+UseG1GC -XX:InitiatingHeapOccupancyPercent=75"
fi
echo "[HELK-ES-DOCKER-INSTALLATION-INFO] Setting ES_JAVA_OPTS to $ES_JAVA_OPTS"

# ******** Checking License Type ***************
ENVIRONMENT_VARIABLES=$(env)
XPACK_LICENSE_TYPE="$(echo $ENVIRONMENT_VARIABLES | grep -oE 'xpack.license.self_generated.type=[^ ]*' | sed s/.*=//)"

# ******** Set Trial License Variables ***************
if [[ $XPACK_LICENSE_TYPE == "trial" ]]; then
  # *********** HELK ES Password ***************
  if [[ -z "$ELASTIC_PASSWORD" ]]; then
    export ELASTIC_PASSWORD=elasticpassword
  fi
  echo "[HELK-ES-DOCKER-INSTALLATION-INFO] Setting Elastic password to $ELASTIC_PASSWORD"
fi

echo "[HELK-ES-DOCKER-INSTALLATION-INFO] Setting Elastic license to $XPACK_LICENSE_TYPE"

# ********** Starting Elasticsearch *****************
echo "[HELK-ES-DOCKER-INSTALLATION-INFO] Running docker-entrypoint script.."
/usr/local/bin/docker-entrypoint.sh