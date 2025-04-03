#!/bin/bash
find /uora/app/oracle/admin/nancy/adump/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/rdbms/nancy/nancy/alert/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/rdbms/nancy/nancy/trace/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/tnslsnr/nancy/listener/alert/ -type f -mtime +7 -exec rm {} \;
find /uora/app/oracle/diag/tnslsnr/nancy/listener/trace/ -type f -mtime +7 -exec rm {} \;