defmodule WorkerPool.Utils do
    require Logger

    def place_for(fields, inc \\ 0) do
        String.duplicate(",?", length(String.split(fields, ",")) + inc)
        |> String.lstrip(?,)
    end

    def to_map(x), do: x |> dict_undefined_to_nil
    def array_to_map(arr) when is_map(arr), do: arr
    def array_to_map(arr) when is_list(arr) do
        Enum.map arr, &dict_undefined_to_nil/1
    end

    def dict_undefined_to_nil(nil), do: nil
    def dict_undefined_to_nil(dict) do
        Dict.to_list(dict) 
        |> Enum.map(fn({key, :undefined}) -> {key, nil}
                      ({key, val}) -> {key, val}
                    end)
        |> Enum.into %{}
    end
    def dict_undefined_to_empty(nil), do: ""
    def dict_undefined_to_empty(dict) do
        Dict.to_list(dict) 
        |> Enum.map(fn({key, :undefined}) -> {key, ""}
                      ({key, val}) -> {key, val}
                    end)
        |> Enum.into %{}
    end

    def list_undefined_to_nil(nil), do: nil
    def list_undefined_to_nil(list) when is_list(list) do
        Enum.map list, &dict_undefined_to_nil/1
    end

    def extra_decode(object, extra_names) when is_list(extra_names) do
        Enum.reduce extra_names, object, fn(extra_name, object)-> json_decode(object, [extra_name]) end
    end
    def extra_decode(object, extra_name), do: json_decode(object, [extra_name])
    def extra_decode(object), do: json_decode(object, [:extra])
    def extra_encode(extra), do: json_encode(extra)

    def json_decode(nil), do: nil
    def json_decode([]), do: []
    def json_decode(object), do: json_decode(object, [:spin_data])
    def json_decode(nil, _), do: nil
    def json_decode([], _), do: []
    def json_decode(objects, json_name) when is_list(objects) do
        Enum.map objects, fn(object)->
            json_decode(object, json_name)
        end
    end
    def json_decode(object, json_name) do
        update_in(object, json_name, 
            fn(nil)-> nil; 
            (:undefined) -> nil;
            (json)-> :jiffy.decode(json, [:return_maps, :atom_keys, :use_nil])
        end)
    end

    def json_encode(data) do
        case data do
            nil -> nil
            :undefined -> nil
            data -> :jiffy.encode(data, [:use_nil])
        end
    end

    def extra_merge(nil, _, _), do: nil
    def extra_merge(object, fields, into \\ :extra) do
        new_extra = Enum.reduce(fields, object[into] || %{}, fn(field, acc)->
            Dict.merge acc, object[field] || %{}
        end)
        Dict.put object, into, new_extra
    end


    def get_execute_result(result_list, error) when is_list(result_list) do
        result = Enum.find_value result_list, 
            fn({:ok_packet, _, _, _, _, _, _})-> false
              ({:error_packet, _, _, _, message})-> message
            end

        case result do
            nil -> :ok
            message ->
                Logger.error "#{error}: #{message}"
                {:error, message}
        end
    end

    def get_execute_result({:ok_packet, _, _, _, _, _, _}, _error), do: :ok
    def get_execute_result({:error_packet, _, _, _, message}, error) do
            Logger.error "#{error}: #{message}"
        {:error, message}
    end

    def get_spin_id(id), do: [div(id,10000), rem(id,10000)]
    def get_spin_id(pack_id, spin_id), do: (pack_id * 10000) + spin_id

    def get_run_result(result, error), do: get_run_result(result, error, %{always_list: false, ignore_errors: true})
    def get_run_result(result, error, opts) when is_list(opts), do: 
        get_run_result(result, error, Enum.into(opts, %{}))
    def get_run_result(result, error, opts = %{}) do
        case {result, opts} do
            {{:error, message}, %{ignore_errors: true}} -> 
                Logger.error "#{error}: #{message}"
                nil
            {[[error: message]], %{ignore_errors: true}} -> 
                Logger.error "#{error}: #{message}"
                nil
            {[[status: "error", message: message]], %{ignore_errors: true}} -> 
                Logger.error "#{error}: #{message}"
                nil

            {{:error, message}, _} ->  {:error, message}
            {[[error: message]], _} ->  {:error, message}
            {[[status: "error", message: message]], _} -> {:error, message}

            {[], %{always_list: true}} -> []
            {[], _} -> nil
            
            {[[result: result]], %{always_list: false}}  -> result
            {list, %{always_list: true}} -> list |> array_to_map

            {[result], _} -> result |> to_map
            {result, _} -> result |> array_to_map
        end        
    end

end
