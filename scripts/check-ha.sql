-- Always On / HA status (run on either replica)
SET NOCOUNT ON;

SELECT
    ag.name AS availability_group,
    ar.replica_server_name,
    ars.role_desc,
    ars.operational_state_desc,
    ars.connected_state_desc,
    ars.synchronization_health_desc,
    ars.last_connect_error_description
FROM sys.dm_hadr_availability_replica_states AS ars
INNER JOIN sys.availability_replicas AS ar
    ON ars.replica_id = ar.replica_id
INNER JOIN sys.availability_groups AS ag
    ON ar.group_id = ag.group_id
ORDER BY ag.name, ars.role_desc;

SELECT
    ag.name AS availability_group,
    db_name(drs.database_id) AS database_name,
    ar.replica_server_name,
    drs.is_local,
    drs.is_primary_replica,
    drs.synchronization_state_desc,
    drs.synchronization_health_desc,
    drs.database_state_desc,
    drs.is_suspended,
    drs.suspend_reason_desc,
    drs.log_send_queue_size,
    drs.redo_queue_size
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_replicas AS ar
    ON drs.replica_id = ar.replica_id
INNER JOIN sys.availability_groups AS ag
    ON ar.group_id = ag.group_id
ORDER BY ag.name, database_name, ar.replica_server_name;

-- Cluster node membership (if WSFC-backed)
SELECT
    member_name,
    member_type_desc,
    member_state_desc,
    number_of_quorum_votes
FROM sys.dm_hadr_cluster_members;
