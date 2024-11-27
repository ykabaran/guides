create user account_main identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to account_main;
alter session set current_schema = account_main;

create table app_object (
  id number(32,0),
  parent_id number(32,0), -- in order to group and organize types
  name varchar2(1023),
  data varchar2(32767)
);
ALTER TABLE app_object ADD CONSTRAINT pk_app_object PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index; -- all tables have this
CREATE INDEX ind_app_object_parent_id ON app_object (parent_id) tablespace APP_MAIN_INDEX;

create table account (
  id number(32,0),
  type number(32,0), -- app_object, payment_account/commission_account
  currency number(32,0), -- app_object
  balance number(32,0) -- stored as integer, decimal precision is determined by the given currency

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
);

create table contract (
  id number(32,0),
  type number(32,0), -- 

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
);
CREATE INDEX on (parent_id);

create table contract_step (
  id number(32,0),
  contract_id number(32,0), -- nesting transactions can be useful for multi-step transactions
  step_num number(16,0),
  type number(32,0), -- 

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
);
CREATE INDEX on (parent_id);

create table transaction (
  id number(32,0),
  contract_id number(32,0),
  contract_step_id number(32,0),
  account_id number(32,0),
  type number(32,0), -- 

  direction number(32,0), -- app_object, input/output
  amount number(32,0) -- always a positive number, negative is determined by the direction

  create_date number(32,0),
  status varchar2(1023),
  version number(16,0),
  change_date number(32,0),

  partition_date date not null
);
CREATE INDEX on (transaction_id);
CREATE INDEX on (account_id);