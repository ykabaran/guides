select * from LOG_STRING order by LAST_USE_DATE desc;

select l.*,
       s1.string_value stack_trace_string ,
       s2.string_value LOG_STACK_TRACE_STRING
from system_log l
	left join log_string s1 on s1.STRING_HASH = l.STACK_TRACE_STRING_HASH
	left join log_string s2 on s2.STRING_HASH = l.LOG_STACK_TRACE_STRING_HASH
order by l.CREATE_DATE desc;

select a.*,
       s1.string_value user_agent_string
from ACCESS_LOG a
left join log_string s1 on s1.STRING_HASH = a.user_agent_string_hash
order by a.CREATE_DATE desc;

select l.*, d.*, s1.STRING_VALUE SQL_STRING
from sql_log l
left join SQL_LOG_DETAIL d on d.TRANSACTION_ID = l.TRANSACTION_ID
left join LOG_STRING s1 on s1.STRING_HASH = d.SQL_STRING_HASH
order by l.START_DATE desc, d.SEQUENCE_NUM asc;

-- truncate table sql_log drop all storage;
-- truncate table sql_log_detail drop all storage;
-- truncate table access_log drop all storage;
-- truncate table system_log drop all storage;
-- truncate table LOG_STRING drop all storage;