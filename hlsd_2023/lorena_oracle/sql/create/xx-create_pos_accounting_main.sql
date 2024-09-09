create user pos_accounting identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to pos_accounting;
alter session set current_schema = pos_accounting;

create table app_object (
  id number(32,0),
  parent_id number(32,0), -- in order to group and organize types
  code varchar2(1023),
  name varchar2(1023),
  data varchar2(32767)
);
ALTER TABLE app_object ADD CONSTRAINT pk_app_object PRIMARY KEY (id) USING INDEX TABLESPACE app_main_index; -- all tables have this
CREATE INDEX ind_app_object_parent_id ON app_object (parent_id) tablespace APP_MAIN_INDEX;

create table app_user (
  id number(32,0),
  name varchar2(1023), -- this is the login name, all other data goes to app_user_info
  status number(32,0) -- app_object, active/disabled
);
CREATE INDEX on (name);

create table app_user_info (
  id number(32,0),
  user_id number(32,0),
  type number(32,0), -- app_object, email_address/phone_number/password_hash
  status number(32,0),
  value varchar2(32767)
);
CREATE INDEX on (user_id);

create table account (
  id number(32,0),
  type number(32,0), -- app_object, payment_account/commission_account
  currency number(32,0), -- app_object
  status number(32,0), -- app_object
  balance number(32,0) -- stored as integer, decimal precision is determined by the given currency
);

create table transaction (
  id number(32,0),
  parent_id number(32,0), -- nesting transactions can be useful for multi-step transactions
  type number(32,0), -- app_object, food_purchase/commission_payment/refund/add_balance_to_card/etc
  status number(32,0) -- app_object, initialized/in_process/errored/cancelled/finalized/abandoned
);
CREATE INDEX on (parent_id);

create table transaction_detail (
  id number(32,0),
  transaction_id number(32,0),
  account_id number(32,0),
  direction number(32,0), -- app_object, input/output
  status number(32,0), -- app_object, initialized/in_process/errored/cancelled/finalized/abandoned
  amount number(32,0) -- always a positive number, negative is determined by the direction
);
CREATE INDEX on (transaction_id);
CREATE INDEX on (account_id);

create table payment_card (
  id number(32,0),
  serial_number varchar2(1023),
  status number(32,0) -- app_object, active/disabled
);
CREATE INDEX on (serial_number);

create table venue (
  id number(32,0),
  name varchar2(1023),
  time_zone number(32,0), -- app_object, UTC+3 or Europe/Nicosia
  status number(32,0) -- app_object, active/disabled
);

create table vendor (
  id number(32,0),
  name varchar2(1023),
  status number(32,0) -- app_object, active/disabled
);

create table vendor_user (
  id number(32,0),
  vendor_id number(32,0),
  user_id number(32,0),
  status number(32,0) -- app_object, active/disabled
);
CREATE INDEX on (vendor_id);

create table venue_event (
  id number(32,0),
  venue_id number(32,0),
  name varchar2(1023),
  start_date number(32,0), -- unix timestamp
  payment_key varchar2(32767), -- RSA key pair for the event
  status number(32,0) -- app_object, scheduled/active/ended/cancelled
);
CREATE INDEX on (venue_id);

create table event_vendor (
  id number(32,0),
  event_id number(32,0),
  vendor_id number(32,0),
  account_id number(32,0), -- assign a new account to a vendor for each event
  payment_key varchar2(32767), -- assign an RSA key pair for each vendor
  status number(32,0) -- app_object, active/disabled
);
CREATE INDEX on (event_id);
CREATE INDEX on (vendor_id);

create table user_payment_card (
  id number(32,0),
  user_id number(32,0),
  card_id number(32,0),
  event_id number(32,0), -- cards are per user per event
  account_id number(32,0),
  status number(32,0) -- app_object, active/disabled
);
CREATE INDEX on (user_id);
CREATE INDEX on (card_id);
CREATE INDEX on (event_id);

create table product (
  id number(32,0),
  category_id number(32,0), -- app_object
  name varchar2(1023),
  status number(32,0)
);
CREATE INDEX on (category_id);

create table vendor_product (
  id number(32,0),
  vendor_id number(32,0),
  category_id number(32,0), -- app_object
  product_id number(32,0),
  price_currency_id number(32,0), -- maybe this should be separated into vendor_product_price table?
  price number(32,0),
  status number(32,0) -- app_object, active/disabled
);
CREATE INDEX on (vendor_id);
CREATE INDEX on (category_id);
CREATE INDEX on (product_id);

create table vendor_sale (
  id number(32,0),
  vendor_id number(32,0),
  transaction_id number(32,0),
  sale_currency_id number(32,0), -- copy the sale price on the sale record, prices can change in the future
  sale_price number(32,0),
  status number(32,0) -- app_object, initialized/in_process/finalized/cancelled/refunded
);
CREATE INDEX on (vendor_id);
CREATE INDEX on (transaction_id);

create table vendor_sale_product (
  id number(32,0),
  sale_id number(32,0),
  product_id number(32,0),
  product_count number(6,0),
  price_currency_id number(32,0),
  unit_price number(32,0), -- copy the sale price here as well
  status number(32,0) -- app_object, active/deleted
);
CREATE INDEX on (sale_id);
CREATE INDEX on (product_id);


/*
  what about kdv or other sales taxes?
  what about modifying an existing sale and adding/removing products?
*/