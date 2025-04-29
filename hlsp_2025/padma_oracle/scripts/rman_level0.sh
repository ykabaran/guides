#!/bin/bash
. /home/oracle/scripts/set_env.sh
logfile="$RMAN_LOGS/rman_$(date +'%Y%m%d_%H%M%S').log"
rman target / nocatalog @/home/oracle/scripts/level0.rmn log="$logfile" >>/dev/null
