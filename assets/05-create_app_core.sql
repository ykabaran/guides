create table system_param (
  owner varchar2(1023),
	param_code varchar2(1023),
	param_value varchar2(32767),
	description varchar2(32767),
	type varchar2(1023), -- PERMANENT, UPDATEABLE, TEMPORARY
	status varchar2(1023),
	update_date number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp
);

create table service_client (
  owner varchar2(1023),
  client_id varchar2(1023),
  name varchar2(1023),
  type varchar2(1023), -- WE_SERVE, THEY_SERVE, BOTH_SERVE
  status varchar2(1023), -- ACTIVE, DISABLED
  data varchar2(32767),
  service_base varchar2(1023),
  server_base varchar2(1023),
  client_public_key varchar2(32767),
  auth_secret varchar2(32767),
  server_public_key varchar2(32767),
  server_private_key varchar2(32767),
  server_passphrase varchar2(32767),
	create_date number(32,0),
	create_ts timestamp default systimestamp
);

GRANT SELECT, INSERT, UPDATE ON system_param TO app_user_role;
GRANT SELECT ON service_client TO app_user_role;
GRANT INSERT, UPDATE ON service_client TO app_admin_role;
