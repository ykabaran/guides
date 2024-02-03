-- SKIPPED

alter session set current_schema=app_log;

/*
create table system_trace (
	trace_id varchar2(1023),
	endpoint_id varchar2(1023),
	instance_id varchar2(1023),
	thread_source varchar2(1023),
	access_id varchar2(1023),
	client_id varchar2(1023),
	session_id varchar2(1023),
	user_id varchar2(1023),
	service_id varchar2(1023),
	user_role_id varchar2(1023),
	create_date date default sysdate
);
*/

create table log_string (
	string_hash varchar2(1023) constraint pk_log_string_hash primary key,
	string_value clob,
	last_use_date number(32,0),
	create_date date default sysdate
);

create table system_log (
	trace_id varchar2(1023),
	endpoint_id varchar2(1023),
	instance_id varchar2(1023),
	thread_source varchar2(1023),

	logger_name varchar2(1023),
	log_level varchar2(1023),
	log_message varchar2(32767),
	log_data clob,
	tags varchar2(1023),
	stack_trace_string_hash varchar2(1023),
	log_stack_trace_string_hash varchar2(1023),
	log_date number(32,0),
	create_date date default sysdate
)
partition by range(create_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);

create table sql_log (
	connection_id varchar2(1023),
	sequence_num number(32,0),
	transaction_id varchar2(1023),

	trace_id varchar2(1023),
	endpoint_id varchar2(1023),
	instance_id varchar2(1023),
	thread_source varchar2(1023),

	status varchar2(1023), -- started, unresponsive, finished
	start_date number(32,0),
	end_date number(32,0),
	create_date date default sysdate
)
partition by range(create_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);

create table sql_log_detail (
	transaction_id varchar2(1023),
	sequence_num number(32,0),

	sql_string_hash varchar2(1023),
	sql_binding varchar2(32767),
	error_log_id varchar2(1023),

	tags varchar2(1023),
	start_date number(32,0),
	end_date number(32,0),
	create_date date default sysdate
)
partition by range(create_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);

create table access_log (
	trace_id varchar2(1023),
	endpoint_id varchar2(1023),
	instance_id varchar2(1023),
	access_id varchar2(1023),
	client_id varchar2(1023),
	session_id varchar2(1023),
	user_id varchar2(1023),

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
	create_date date default sysdate
)
partition by range(create_date)
interval (numtodsinterval(1,'day'))
(partition p0 values less than
  (to_date('2023-01-01','YYYY-MM-DD'))
);

GRANT SELECT, INSERT, UPDATE ON log_string TO app_log_role;
GRANT INSERT ON system_log TO app_log_role;
GRANT SELECT, INSERT, UPDATE ON sql_log TO app_log_role;
GRANT INSERT ON sql_log_detail TO app_log_role;
GRANT INSERT ON access_log TO app_log_role;

GRANT SELECT ON log_string TO app_log_analyzer_role;
GRANT SELECT ON system_log TO app_log_analyzer_role;
GRANT SELECT ON sql_log TO app_log_analyzer_role;
GRANT SELECT ON sql_log_detail TO app_log_analyzer_role;
GRANT SELECT ON access_log TO app_log_analyzer_role;

-- drop table log_string;
-- drop table system_log;
-- drop table sql_log;
-- drop table sql_log_detail;
-- drop table access_log;
-- drop table app_instance;
-- drop table app_instance_state_log;
-- drop table app_service_log;
-- drop table app_data_file_log;
-- drop table app_data_change_log;

-- truncate table log_string drop all storage cascade;
-- truncate table system_log drop all storage cascade;
-- truncate table sql_log drop all storage cascade;
-- truncate table sql_log_detail drop all storage cascade;
-- truncate table access_log drop all storage cascade;
-- truncate table app_instance drop all storage cascade;
-- truncate table app_instance_state_log drop all storage cascade;
-- truncate table app_service_log drop all storage cascade;
-- truncate table app_data_file_log drop all storage cascade;
-- truncate table app_data_change_log drop all storage cascade;