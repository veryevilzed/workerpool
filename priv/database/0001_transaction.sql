
CREATE TABLE IF NOT EXISTS workerpool_transaction_lock (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name varchar(200) NOT NULL, #WORKER NAME
    trx varchar(64) NOT NULL,
    last_update DATETIME NOT NULL DEFAULT NOW(),
    pool varchar(60) NOT NULL DEFAULT "default",
    KEY(trx, pool),
    KEY(last_update),
    UNIQUE(trx, pool)
) ENGINE=InnoDB CHARACTER SET=UTF8;


CREATE PROCEDURE sp_workerpool_get_lock(_pool VARCHAR(60), _trx VARCHAR(64), _timeout_seconds INT)
BEGIN
    DECLARE _worker VARCHAR(65);
    DECLARE exit handler for sqlexception
      BEGIN
        GET DIAGNOSTICS CONDITION 1 @message = MESSAGE_TEXT;
        SELECT 'error' as status, @message as message;
      ROLLBACK;
    END;

    START TRANSACTION;
        DELETE FROM workerpool_transaction_lock WHERE UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(last_update) > _timeout_seconds LIMIT 10;
        SELECT name INTO _worker FROM workerpool_transaction_lock WHERE pool=_pool AND trx=_trx;
        IF _worker IS NULL THEN
            SELECT name INTO _worker FROM workerpool WHERE last_update>now() ORDER BY RAND() LIMIT 1;
            IF _worker IS NULL THEN
                SELECT 'error' AS status, 'worker not found' as message;
            ELSE
                INSERT INTO workerpool_transaction_lock(name, trx, pool) VALUES (_worker, _trx, _pool);
                SELECT 'ok' AS status, _worker AS worker;
            END IF;
        ELSE
            UPDATE workerpool_transaction_lock SET last_update=now() WHERE pool=_pool AND trx=_trx;
            SELECT 'ok' AS status, _worker AS worker;
        END IF;
    COMMIT;
END;