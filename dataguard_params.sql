alter system set log_archive_config='DG_CONFIG=(DB0, DB0DG)' scope=both sid='*';  ----------standby da-----------
alter system set log_archive_config='DG_CONFIG=(DB0, DB0DG)' scope=both sid='*';  ----------prod da -----------
alter system set fal_server='DB0DG' scope=both sid='*'; -----------dg---------
alter system set fal_client='DB0DB' scope=both sid='*';   -----------dg---------
alter system set fal_server='DB0DB' scope=both sid='*';  ----------prod da -----------
alter system set fal_client='DB0DG' scope=both sid='*';  ----------prod da -----------