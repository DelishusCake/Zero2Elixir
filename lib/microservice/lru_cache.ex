defmodule LruCache do
  @moduledoc """
  Defines a simple implementation of an LRU caching scheme
  """

  defstruct max_size: 20, queue: [], values: %{}

  @doc """
  Construct a new LRU Cache with a maximum number of elements
  """
  def new(max_size) do
    %LruCache{max_size: max_size}
  end

  @doc """
  Check if the cache contains a key already.
  Does not alter the cache
  """
  def contains?(cache, key), do: Map.has_key?(cache.values, key)

  @doc """
  Check if the cache is full.
  Does not alter the cache
  """
  def full?(cache), do: length(cache.queue) > cache.max_size - 1

  @doc """
  Put a value into the LRU cache, possibly evicting older values
  Returns a new cache
  """
  def put(cache, key, value) do
    # If the cache already contains the key
    if contains?(cache, key) do
      # Move the key to the front of the queue
      move_to_front(cache, key)
    else
      # Maybe evict the last element inserted if the cache is full
      cache = maybe_evict(cache)
      # Put the new key at the front of the queue
      new_queue = [key | cache.queue]
      # Put the new value into the lookup map
      new_values = Map.put(cache.values, key, value)
      # Return the new cache
      %{cache | queue: new_queue, values: new_values}
    end
  end

  @doc """
  Get a value from the cache, reordering values as needed
  Returns a tuple of { :some, cache, value } if the key is in the cache,
  or { :none, cache } if the key is not in the cache
  """
  def get(cache, key) do
    if contains?(cache, key) do
      # Return a tuple of the new, reordered cache and the value
      {:some, refer(cache, key), cache.values[key]}
    else
      {:none, cache}
    end
  end

  @doc """
  Get a value from the cache, reordering values as needed. 
  Raises a KeyError if the key is missing from the cache.
  """
  def get!(cache, key) do
    # Check if the value is in the cache
    if not contains?(cache, key), do: raise(KeyError, message: "#{key} is missing")
    # Return a tuple of the new, reordered cache and the value
    {refer(cache, key), cache.values[key]}
  end

  defp refer(cache, key) do
    # If the cache already contains the key
    if contains?(cache, key) do
      # Move the key to the front of the queue
      move_to_front(cache, key)
    else
      # If the value isn't in the cache, maybe evict the last inserted value 
      maybe_evict(cache)
    end
  end

  defp move_to_front(cache, key) do
    # Move the key to the front of the queue
    new_queue = [key | List.delete(cache.queue, key)]
    # Update the cache with the new queue
    %{cache | queue: new_queue}
  end

  defp maybe_evict(cache) do
    # If the cache is full
    if full?(cache) do
      # Remove the last key in the queue and get the new queue
      {last_key, new_queue} = List.pop_at(cache.queue, -1)
      # Remove the value that the last inserted key points to from the values
      {_, new_values} = Map.pop(cache.values, last_key)
      # Return a new cache with the queue and values
      %{cache | queue: new_queue, values: new_values}
    else
      # Cache is not full, return the unaltered cache
      cache
    end
  end
end
