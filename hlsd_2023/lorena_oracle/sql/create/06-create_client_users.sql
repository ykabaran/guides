create user app_test_user01 identified by "";
grant connect to app_test_user01;
grant app_core_reader to app_test_user01;

create user pa_feed_file_creator01 identified by "";
grant connect to pa_feed_file_creator01;
grant pa_feed_writer to pa_feed_file_creator01;

create user fs_feed_file_creator01 identified by "";
grant connect to fs_feed_file_creator01;
grant fs_feed_writer to fs_feed_file_creator01;

create user ls_data_writer01 identified by "";
grant connect to ls_data_writer01;
grant ls_data_writer to ls_data_writer01;
grant ls_prematch_feed_writer to ls_data_writer01;
grant ls_inplay_feed_writer to ls_data_writer01;
	