create user hls_game_app_user identified by "";
grant connect,
		app_core_reader,
		app_user_writer,
		app_accounting_reader,
		hls_game_writer,
		hls_instant_game_writer,
		hls_game_analytics_writer
	to hls_game_app_user;

create user hls_admin_app_user identified by "";
grant connect,
		app_core_writer,
		app_user_writer,
		app_accounting_writer,
		hls_game_writer,
		hls_instant_game_writer,
		hls_game_analytics_writer
	to hls_admin_app_user;