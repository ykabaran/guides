create user app_test_user01 identified by "";
grant connect,
		app_log_writer,
		app_core_log_writer,
		ls_log_writer,
		gs_log_writer
	to app_test_user01;