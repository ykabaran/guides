create user hlbs_app identified by ""
  default tablespace APP_MAIN
  quota unlimited on APP_MAIN
  quota unlimited on APP_MAIN_INDEX;

grant connect, resource to hlbs_app;

alter session set current_schema=hlbs_app;

grant select on app_user.APP_USER to hlbs_app with grant option;
grant select on APP_ACCOUNTING.APP_CURRENCY to hlbs_app with grant option;
grant select on hls_game.GAME to hlbs_app with grant option;
grant select on hls_instant_game.GAME_PRIZE to hlbs_app with grant option;
grant select on hls_instant_game.GAME_PRIZE_group to hlbs_app with grant option;
grant select on hls_instant_game.GAME_PRIZE_REDEMPTION to hlbs_app with grant option;

grant select on HLS_GAME_ANALYTICS.GAME_ANALYTICS_DAILY to hlbs_app with grant option;
grant select on HLS_GAME_ANALYTICS.GAME_ANALYTICS_hourly to hlbs_app with grant option;
grant select on HLS_GAME_ANALYTICS.GAME_ANALYTICS_minutely to hlbs_app with grant option;
grant select on HLS_GAME_ANALYTICS.GAME_user_ANALYTICS_DAILY to hlbs_app with grant option;
grant select on HLS_GAME_ANALYTICS.GAME_user_ANALYTICS_hourly to hlbs_app with grant option;
grant select on HLS_GAME_ANALYTICS.GAME_user_ANALYTICS_minutely to hlbs_app with grant option;

create or replace view view_hlbs_betcard
as
(select
  app_core.PKG_DATE.to_date(r.create_date) create_date,
  app_core.pkg_uid.to_string(r.id) card_id,
  app_core.pkg_uid.to_string(game.id) game_id,
  game.code game_code,
  app_core.pkg_uid.to_string(currency.id) currency_id,
  currency.code currency_code,
  app_core.pkg_uid.to_string(g.id) group_id,
  g.PRIZE_TYPE prize_type,
  app_core.pkg_uid.to_string(r.prize_id) prize_id,
  to_number(substr(u.USERNAME, 26)) sub_id,
  r.bet_stake / power(10,currency.PRECISION) bet_stake,
  case when instr(r.data, '"hlbs_bonus_stake":"') > 0 then
    to_number(substr(r.data,
           instr(r.data, '"hlbs_bonus_stake":"') + length('"hlbs_bonus_stake":"'),
           instr(r.data, '"', instr(r.data, '"hlbs_bonus_stake":"') + length('"hlbs_bonus_stake":"')) - (instr(r.data, '"hlbs_bonus_stake":"') + length('"hlbs_bonus_stake":"'))
    ))
    else 0 end bet_stake_bonus,
  r.bet_return / power(10,currency.PRECISION) bet_return,
  decode(r.status, 'finished', case when r.bet_return > 0 then 'W' else 'L' end, 'active', 'O', 'U') bet_status,
  'https://' || (decode(game.code, 'slot_hot_bells', 'hotbells', 'slot_bonanza_ufo', 'bonanzaufo', 'slot_bonanza', 'bonanza', 'unknown'))
    || '.slothinteractive.com/index.html?lang=TR&redemption_id=' || app_core.pkg_uid.to_string(r.id) || '&secret_key=' || r.secret_key replay_url
from hls_instant_game.GAME_PRIZE_REDEMPTION r
  left join HLS_INSTANT_GAME.GAME_PRIZE_GROUP g on r.PRIZE_GROUP_ID = g.id
  left join hls_game.game game on r.game_id = game.ID
  left join app_accounting.APP_CURRENCY currency on g.currency_id = currency.ID
  left join app_user.app_user u on r.user_id = u.id);

create or replace view VIEW_HLBS_BETCARD_HOURLY as
select
       app_core.PKG_DATE.TO_DATE(ad.start_date) hour,
       game.code game_code,
       to_number(substr(u.USERNAME, 26)) sub_id,
       sum(ad.total_count) bet_count,
       sum(ad.total_stake)/(power(10, currency.PRECISION)) total_stake,
       sum(ad.total_return)/(power(10, currency.PRECISION)) total_return
    from HLS_GAME_ANALYTICS.GAME_USER_ANALYTICS_hourly ad
  left join hls_game.game game on game.id = ad.GAME_ID
    left  join app_accounting.APP_CURRENCY currency on currency.code = ad.CURRENCY_CODE
    left join app_user.APP_USER u on u.id = ad.USER_ID
where currency.code = 'TRY' and ad.STATUS = 'active' and ad.HOUSE_ID = 491502415850061455050619022
group by ad.START_DATE, game.code, currency.code, currency.precision, u.username
order by ad.start_date desc, sub_id asc, game.code asc;