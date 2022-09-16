defmodule Microservice.Newsletter.SubscriptionCache do
  use GenServer

  def get_or_cache(key, func) do
    case get(key) do
      :none ->
        value = func.()
        put(key, value)
        value
      value -> value
    end
  end

  def get(key), do: GenServer.call(__MODULE__, {:get, key})

  def put(key, value), do: GenServer.call(__MODULE__, {:put, key, value})

  def clear(), do: GenServer.call(__MODULE__, :clear)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts), do: { :ok, create() }

  def handle_call({:get, key}, _from, cache) do
    case LruCache.get(cache, key) do
      {:some, cache, value} -> { :reply, value, cache }
      {:none, cache} -> {:reply, :none, cache}
    end
  end

  def handle_call({:put, key, value}, _from, cache) do
    cache = LruCache.put(cache, key, value)
    { :reply, :ok, cache }
  end

  def handle_call(:clear, _from, _cache) do
    { :reply, :ok, create() }
  end

  defp create(), do: LruCache.new(32)
end
