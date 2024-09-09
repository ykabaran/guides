create user app_test_user01 identified by "";
grant connect, app_core_writer, app_localization_writer, app_parameter_writer, app_key_writer, app_user_writer to app_test_user01;

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