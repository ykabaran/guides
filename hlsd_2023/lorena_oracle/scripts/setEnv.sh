# Oracle Settings
export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_SID=lorena
export ORACLE_HOSTNAME=lorena.hlsd.com
export ORACLE_UNQNAME=$ORACLE_SID

export ORACLE_BASE=/uora/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
export ORA_INVENTORY=/uora/app/oraInventory
export DATA_DIR=/uoradata
export BACKUP_DIR=/uorabackup

export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

export P_FILE=$ORACLE_HOME/dbs/init$ORACLE_SID.ora
export SP_FILE=$ORACLE_HOME/dbs/spfile$ORACLE_SIDd.ora
export ALERT_LOG=$ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log
export CONTROL_FILE=$DATA_DIR/$ORACLE_UNQNAME/CONTROL0d.CTL
export RMAN_LOGS=/uorabackup/logs
export NLS_DATE_FORMAT="yyyy-mm-dd hh24:mi:ss"