use Mix.Config


config :cache, 
    workerpool_cache: [n: 10, ttl: 60]

config :exsouth,
    workerpool: []


config :workerpool,
    mysql: [size: 10, host: 'localhost', database: 'workerpool', user: 'root']


config :workerpool, :pools, 
    default_pool: [
        refresh_timeout: :timer.seconds(20),
        worker_life_time: :timer.seconds(60)
    ],
    pool_1: [
        refresh_timeout: :timer.seconds(5),
        worker_life_time: :timer.seconds(5)
    ]
