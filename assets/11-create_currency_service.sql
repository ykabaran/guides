create user CURRENCY_SERVICE identified by "tv9JDvaW2HbUqGMw"
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;
grant connect, resource to CURRENCY_SERVICE;

create table currency_market_value (
	currency_from_id varchar2(1023),
	currency_to_id varchar2(1023),
	buy_value number(32,0),
	buy_value_scale number(2,0),
	sell_value number(32,0),
	sell_value_scale number(2,0),
	value_date number(32,0),
	value_expires_date number(32,0),
	create_ts timestamp default systimestamp
);

create table currency_market_value_update (
	currency_from_id varchar2(1023),
	currency_to_id varchar2(1023),
	buy_value number(32,0),
	buy_value_scale number(2,0),
	sell_value number(32,0),
	sell_value_scale number(2,0),
	create_date number(32,0),
	valid_from_date number(32,0),
	valid_to_date number(32,0),
	create_ts timestamp default systimestamp
)
partition by range(create_ts)
interval (numtodsinterval(7,'day'))
(partition p0 values less than
  (to_date('2021-01-01','YYYY-MM-DD'))
);

GRANT SELECT, INSERT, UPDATE ON currency_market_value TO app_user_role;
GRANT SELECT, INSERT, UPDATE ON currency_market_value_update TO app_user_role;