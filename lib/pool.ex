defmodule WorkerPool.Pool do
    
    require Logger

    @pool Keyword.get(Application.get_env(:workerpool, :mysql, []), :pool, :mp)


    defp state(), do: %{ pool_name: "default", workers: :queue.new, refresh_timeout: 60000, worker_life_time: 120000  }

    def start_link(opts \\ []) do
        config = Dict.get(opts, :config, [])
        Logger.info "Start workerpool #{Keyword.get(opts, :id, __MODULE__)}"
        :gen_server.start_link({ :local, Keyword.get(opts, :id, __MODULE__) }, __MODULE__, config, [])
    end

    defp atos(a) when is_atom(a), do: Atom.to_string(a)
    defp atos(a), do: a
        

    def init(opts \\ []) do
        {:ok, 
            %{ state() | 
                refresh_timeout: Dict.get(opts, :refresh_timeout, 60000), 
                worker_life_time: Dict.get(opts, :worker_life_time, 120000),
                pool_name: Dict.get(opts, :pool_name, "default") |> atos
            },
        0}
    end

    defp update_worker(name, state=%{pool_name: pool_name, worker_life_time: lt}) do
        res = SQL.execute("INSERT INTO workerpool (name, pool, last_update) VALUES(?,?, DATE_ADD(now(), INTERVAL #{div(lt,1000)} SECOND)) ON DUPLICATE KEY 
            UPDATE last_update=DATE_ADD(now(), INTERVAL #{div(lt,1000)} SECOND);", [name, pool_name], @pool)

        case res do
            {:error_packet, _, _, _, message} -> :error
            _ -> :ok
        end
    end

    defp reload_workers(state=%{pool_name: pool_name}) do
        SQL.execute("DELETE FROM workerpool WHERE pool=? AND enabled=true AND last_update<now();", [pool_name], @pool)
        case SQL.run("SELECT name FROM workerpool WHERE pool=? AND enabled=true AND last_update>now();", [pool_name], @pool) do
            [] -> %{state| workers: :queue.new}
            data -> %{state| workers: Enum.reduce(data, :queue.new, fn([name: name], acc) -> :queue.in(name, acc) end) }
        end        
    end

    def handle_call({:update, name}, _sender, state=%{workers: {[], []}}) do
        res = update_worker(name, state)
        {:reply, res, reload_workers(state)}
    end
    def handle_call({:update, name}, _sender, state) do
        {:reply, update_worker(name, state), state}
    end

    def handle_call(:reload, _sender, state), do: {:reply, :ok, reload_workers(state) }
    def handle_call(:get, _sender, state=%{workers: {[],[]} }), do: {:reply, nil, state }
    def handle_call(:get, _sender, state=%{workers: q}) do
        
        {{:value, item}, q} = :queue.out(q)
        
        {:reply, item, %{state | workers: :queue.in(item, q) }}
    end

    def handle_info(:timeout, state=%{refresh_timeout: rt}) do
        state = reload_workers(state)
        :timer.send_after(rt, :timeout)
        {:noreply, state}
    end


    def terminate(_info, _state), do: :ok

end