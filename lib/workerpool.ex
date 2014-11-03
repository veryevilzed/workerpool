defmodule WorkerPool do
    use Application

    def start(_type, _args) do
        import Supervisor.Spec, warn: false
        
        case Application.get_env(:workerpool, :mysql, nil) do
            nil -> :ok
            data -> 
                case data |> SQL.init do
                    {:error, :pool_already_exists} -> :ok
                    :ok -> :ok
                    {:error, error} -> raise error
                end
        end

        default_pool = [{:default_pool, [refresh_timeout: 10000, worker_life_time: 30000]}]

        pools_config = Dict.merge(default_pool, Application.get_env(:workerpool, :pools, []))

        children = pools_config |> Enum.map(fn({pool_name, pool_config}) -> 
            id = String.to_atom("#{pool_name}")
            pool_config = pool_config |> Dict.put(:pool_name, pool_name)
            worker(WorkerPool.Pool, [[id: id, config: pool_config]], [id: id] )
        end)

        opts = [strategy: :one_for_one, max_restarts: 5000, max_seconds: 10, name: WorkerPool.Supervisor]
        Supervisor.start_link(children, opts)
    end

    def update(pool \\ :default_pool, worker), do: GenServer.call(pool, {:update, worker})
    def get(pool \\ :default_pool), do: GenServer.call(pool, :get)
    def get_by_key(key \\ 0, pool \\ :default_pool), do: GenServer.call(pool, {:get, key})
    def reload(pool \\ :default_pool), do: GenServer.call(pool, :reload)

end
