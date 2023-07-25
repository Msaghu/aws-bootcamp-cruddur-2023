SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE
-- dont kill my own connection
pid <> pg_backend_pid()
-- dont kill the connections to other databases
AND datname = 'cruddur';