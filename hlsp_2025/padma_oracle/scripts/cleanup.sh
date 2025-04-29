#!/bin/bash
find /uora/app/oracle/admin/padma/adump/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/rdbms/padma/padma/alert/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/rdbms/padma/padma/trace/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/tnslsnr/padma/listener/alert/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/tnslsnr/padma/listener/trace/ -type f -mtime +7 -exec rm {} \;