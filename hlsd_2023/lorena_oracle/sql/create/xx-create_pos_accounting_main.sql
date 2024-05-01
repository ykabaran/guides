create user pos_accounting identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX
  quota unlimited on APP_LOG;

grant connect, resource to pos_accounting;
alter session set current_schema = pos_accounting;

create table app_static_type (
  id number(32,0),
  parent_id number(32,0),
  code varchar2(1023),
  name varchar2(1023)
);

create table app_user (
  id number(32,0),
  name varchar2(1023),
  status number(32,0)
);

create table app_user_info (
  id number(32,0),
  user_id number(32,0),
  type number(32,0),
  status number(32,0),
  value varchar2(32767)
);

create table currency (
  id number(32,0),
  code varchar2(1023),
  name varchar2(1023),
  balance_precision number(2,0)
);

create table account (
  id number(32,0),
  type number(32,0),
  currency number(32,0),
  status number(32,0),
  balance number(32,0),
);

create table transaction (
  id number(32,0),
  parent_id number(32,0),
  type number(32,0),
  status number(32,0)
);

create table transaction_detail (
  id number(32,0),
  transaction_id number(32,0),
  account_id number(32,0),
  direction number(32,0),
  status number(32,0),
  amount number(32,0),
);

create table payment_card (
  id number(32,0),
  serial_number varchar2(1023),
  status number(32,0)
);

create table venue (
  id number(32,0),
  name varchar2(1023),
  status number(32,0)
);

create table vendor (
  id number(32,0),
  name varchar2(1023),
  status number(32,0)
);

create table vendor_user (
  id number(32,0),
  vendor_id number(32,0),
  user_id number(32,0),
  status number(32,0)
);

create table venue_event (
  id number(32,0),
  venue_id number(32,0),
  name varchar2(1023),
  start_date number(32,0),
  payment_key varchar2(32767),
  status number(32,0)
);

create table event_vendor (
  id number(32,0),
  event_id number(32,0),
  vendor_id number(32,0),
  account_id number(32,0),
  payment_key varchar2(32767),
  status number(32,0)
);

create table user_payment_card (
  id number(32,0),
  user_id number(32,0),
  card_id number(32,0),
  event_id number(32,0),
  account_id number(32,0),
  status number(32,0)
);

create table product_category (
  id number(32,0),
  name varchar2(1023),
  status number(32,0)
);

create table product (
  id number(32,0),
  category_id number(32,0),
  name varchar2(1023),
  status number(32,0)
);

create table vendor_product (
  id number(32,0),
  vendor_id number(32,0),
  category_id number(32,0),
  product_id number(32,0),
  price_currency_id number(32,0),
  price number(32,0),
  status number(32,0)
);

create table vendor_sale (
  id number(32,0),
  vendor_id number(32,0),
  transaction_id number(32,0),
  sale_currency_id number(32,0),
  sale_price number(32,0),
  status number(32,0)
);

create table vendor_sale_product (
  id number(32,0),
  sale_id number(32,0),
  product_id number(32,0),
  product_count number(6,0),
  price_currency_id number(32,0),
  unit_price number(32,0),
  total_price number(32,0),
  status number(32,0)
);