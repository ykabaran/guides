create user app_test_user01 identified by "";
grant connect,
		app_core_writer,
		app_localization_writer,
		app_parameter_writer,
		app_secret_writer,
		app_user_writer,
		hlbs_report_writer,
		app_core_deleter,
		app_localization_deleter,
		app_parameter_deleter,
		app_user_deleter,
		ls_data_writer,
		gs_data_writer
	to app_test_user01;

create user pa_feed_file_creator01 identified by "";
grant connect, pa_feed_writer to pa_feed_file_creator01;

create user fs_feed_file_creator01 identified by "";
grant connect, fs_feed_writer to fs_feed_file_creator01;

create user ls_data_writer01 identified by "";
grant connect, ls_data_writer, ls_prematch_feed_writer, ls_inplay_feed_writer to ls_data_writer01;

create user hls_sport_writer01 identified by "";
grant connect, app_core_reader, ls_data_reader, hls_sport_writer, fs_data_reader to hls_sport_writer01;

create user goalserve_api_user01 identified by "";
grant connect, goalserve_widget_writer to goalserve_api_user01;