use Mix.Config

config :exsouth,
    workerpool: []


config :workerpool,
    mysql: [size: 10, host: 'localhost', database: 'workerpool', user: 'root']

config :workerpool, :pools, 
    default_pool: [
        refresh_timeout: :timer.seconds(5),
        worker_life_time: :timer.seconds(5)
    ],
    pool_1: [
        refresh_timeout: :timer.seconds(5),
        worker_life_time: :timer.seconds(5)
    ]
