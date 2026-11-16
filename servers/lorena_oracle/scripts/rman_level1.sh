#!/bin/bash
. /home/oracle/scripts/setEnv.sh
logfile="$RMAN_LOGS/rman_$(date +'%Y%m%d_%H%M%S').log"
rman target / nocatalog @/home/oracle/scripts/level1.rmn log="$logfile" >>/dev/null
