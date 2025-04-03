#!/bin/bash
find /uora/app/oracle/admin/lorena/adump/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/rdbms/lorena/lorena/alert/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/rdbms/lorena/lorena/trace/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/tnslsnr/lorena/listener/alert/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/tnslsnr/lorena/listener/trace/ -type f -mtime +7 -exec rm {} \;