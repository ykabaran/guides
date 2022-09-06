BEGIN
    DBMS_NETWORK_ACL_ADMIN.append_host_ace (
        HOST   => '*',
        ace    => xs$ace_type (privilege_list   => xs$name_list ('resolve'),
                               principal_name   => 'PUBLIC',
                               principal_type   => xs_acl.ptype_db));
    DBMS_NETWORK_ACL_ADMIN.append_host_ace (
        HOST   => '*',
        ace    => xs$ace_type (privilege_list   => xs$name_list ('connect'),
                               principal_name   => 'PUBLIC',
                               principal_type   => xs_acl.ptype_db));
END;