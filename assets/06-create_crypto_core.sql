create user CRYPTO_CORE identified by "Ot2m35zSNGPvlkWg"
  default tablespace APP_CORE
  quota unlimited on APP_CORE;
grant connect, resource to CRYPTO_CORE;

create table currency (
	currency_id varchar2(1023), -- TRY, BTC, BTC_TEST, ETH, USD, USDT
	type varchar2(1023), -- REAL, DUMMY
	status varchar2(1023), -- ACTIVE, DISABLED
	data varchar2(32767),
	value_scale number(2,0),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_currency PRIMARY KEY (currency_id)
);

create table blockchain_network (
	network_id varchar2(1023), -- INTERNAL, FIAT, BTC_MAINNET, BTC_TESTNET, ETH_ROPSTEN
	type varchar2(1023), -- REAL, DUMMY
	status varchar2(1023), -- ACTIVE, DISABLED
	data varchar2(32767),
	create_ts timestamp default systimestamp,
	CONSTRAINT pk_blockchain_network PRIMARY KEY (network_id)
);

/*
 this isn't for BTC on MAINNET vs TESTNET, those are different currencies
 this is for currencies like USDT which can exist on Ethereum and Omni at the same time, and are exchangeable
 */
create table currency_network (
	currency_id varchar2(1023),
	network_id varchar2(1023),
	status varchar2(1023), -- ACTIVE, DISABLED
	data varchar2(32767), -- { isToken, tokenContract, etc }
	create_ts timestamp default systimestamp
);

GRANT SELECT ON currency TO app_user_role;
GRANT SELECT ON blockchain_network TO app_user_role;
GRANT SELECT ON currency_network TO app_user_role;
GRANT INSERT, UPDATE ON currency TO app_admin_role;
GRANT INSERT, UPDATE ON blockchain_network TO app_admin_role;
GRANT INSERT, UPDATE ON currency_network TO app_admin_role;