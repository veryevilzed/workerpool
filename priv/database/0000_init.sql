
CREATE TABLE IF NOT EXISTS workerpool (
    name varchar(200),
    last_update DATETIME NOT NULL DEFAULT NOW(),
    pool varchar(60) NOT NULL DEFAULT "default",
    enabled BOOLEAN DEFAULT true,
    PRIMARY KEY(name, pool)
) ENGINE=InnoDB CHARACTER SET=UTF8;