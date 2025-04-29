#!/bin/bash
. /home/oracle/scripts/set_env.sh

export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbstart $ORACLE_HOME
