create table log_string (
	string_hash varchar2(1023) constraint PK_log_string_hash primary key,
	string_value clob,
	last_use_date number(32,0),
	create_date number(32,0),
	create_ts timestamp default systimestamp
);

create table system_log (
	log_id varchar2(1023),
	app_name varchar2(1023),
	trace_id varchar2(1023),
	thread_source varchar2(1023),
	logger_name varchar2(1023),
	log_level varchar2(1023),
	log_message varchar2(32767),
	log_data clob,
	log_tag varchar2(1023),
	stack_trace_string_hash varchar2(1023),
	log_stack_trace_string_hash varchar2(1023),
	log_date number(32,0),
	process_id varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp
)
partition by range(create_ts)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create table sql_log (
	transaction_id varchar2(1023),
	app_name varchar2(1023),
	trace_id varchar2(1023),
	sequence_num number(32,0),
	status varchar2(1023),
	start_date number(32,0),
	end_date number(32,0),
	create_ts timestamp default systimestamp
)
partition by range(create_ts)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create table sql_log_detail (
	transaction_id varchar2(1023),
	sequence_num number(32,0),
	sql_string_hash varchar2(1023),
	sql_binding varchar2(32767),
	start_date number(32,0),
	end_date number(32,0),
	create_ts timestamp default systimestamp
)
partition by range(create_ts)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

create table access_log (
	access_id varchar2(1023),
	app_name varchar2(1023),
	trace_id varchar2(1023),
	session_id varchar2(1023),
	process_id varchar2(1023),
	remote_address_stack varchar2(32767),
	user_agent_string_hash varchar2(1023),
	request_method varchar2(1023),
	request_url varchar2(32767),
	request_headers varchar2(32767),
	request_cookies varchar2(32767),
	request_body clob,
	request_date number(32,0),
	response_http_status number(32,0),
	response_headers varchar2(32767),
	response_cookies varchar2(32767),
	response_body clob,
	response_date number(32,0),
	error_stack_trace_string_hash varchar2(1023),
	create_date number(32,0),
	create_ts timestamp default systimestamp
)
partition by range(create_ts)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

GRANT SELECT, INSERT, UPDATE ON log_string TO app_log_role;
GRANT INSERT ON system_log TO app_log_role;
GRANT SELECT, INSERT, UPDATE ON sql_log TO app_log_role;
GRANT INSERT ON sql_log_detail TO app_log_role;
GRANT INSERT ON access_log TO app_log_role;


-- drop table access_log;
-- drop table sql_log_detail;
-- drop table sql_log;
-- drop table system_log;
-- drop table log_string;