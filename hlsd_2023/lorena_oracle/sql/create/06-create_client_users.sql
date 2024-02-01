create user app_test_user01 identified by "";
grant connect to app_test_user01;
grant app_core_reader to app_test_user01;

create user pa_feed_file_creator01 identified by "";
grant connect to pa_feed_file_creator01;
grant pa_feed_writer to pa_feed_file_creator01;