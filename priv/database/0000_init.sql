
CREATE TABLE IF NOT EXISTS workerpool (
    name varchar(200),
    last_update DATETIME NOT NULL DEFAULT NOW(),
    pool varchar(60) NOT NULL DEFAULT "default",
    enabled BOOLEAN DEFAULT true,
    PRIMARY KEY(name, pool)
) ENGINE=InnoDB CHARACTER SET=UTF8;


CREATE TABLE IF NOT EXISTS workerpool_lock (
    woker_name varchar(200), # Имя воркера
    key VARCHAR(300),        # Лок воркера
    last_update DATETIME NOT NULL DEFAULT NOW(), # Последнее обновление локка
    pool varchar(60) NOT NULL DEFAULT "default", # Пул задач
    PRIMARY KEY(worker_name, pool, key)      
) ENGINE=InnoDB CHARACTER SET=UTF8;