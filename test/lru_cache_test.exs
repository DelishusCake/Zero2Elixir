defmodule LruCacheTest do
  use ExUnit.Case
  doctest LruCache

  test "new/1 constructs a new LRU Cache of correct size" do
    cache = LruCache.new(5)
    assert cache.max_size == 5
  end

  test "put/3 properly inserts values" do
    cache = LruCache.new(5)
    cache = LruCache.put(cache, :test, :value)
    cache = LruCache.put(cache, :test2, :value2)
    cache = LruCache.put(cache, :test3, :value3)

    assert cache.queue == [:test3, :test2, :test]
    assert cache.values == %{test: :value, test2: :value2, test3: :value3}
  end

  test "get/2 returns correct values" do
    cache = LruCache.new(5)
    cache = LruCache.put(cache, :test, :value)
    cache = LruCache.put(cache, :test2, :value2)
    cache = LruCache.put(cache, :test3, :value3)

    {:some,  cache, value_a} = LruCache.get(cache, :test)
    {:some, _cache, value_b} = LruCache.get(cache, :test2)

    assert value_a == :value
    assert value_b == :value2
  end

  test "get/2 returns none for missing key" do
    cache = LruCache.new(5)
    cache = LruCache.put(cache, :test, :value)
    cache = LruCache.put(cache, :test2, :value2)
    cache = LruCache.put(cache, :test3, :value3)

    {:some,  cache, value_a} = LruCache.get(cache, :test)
    {:none, _cache} = LruCache.get(cache, :test4)

    assert value_a == :value
  end

  test "get!/2 raises an error for missing keys" do
    cache = LruCache.new(5)
    cache = LruCache.put(cache, :test, :value)
    cache = LruCache.put(cache, :test2, :value2)
    cache = LruCache.put(cache, :test3, :value3)

    {cache, _} = LruCache.get!(cache, :test)

    assert_raise KeyError, fn ->
      LruCache.get!(cache, :test4)
    end
  end

  test "get/2 reorders the queue" do
    cache = LruCache.new(5)
    cache = LruCache.put(cache, :test, :value)
    cache = LruCache.put(cache, :test2, :value2)
    cache = LruCache.put(cache, :test3, :value3)

    {:some, cache, _} = LruCache.get(cache, :test)

    assert cache.queue == [:test, :test3, :test2]
    assert cache.values == %{test: :value, test2: :value2, test3: :value3}

    {:some, cache, _} = LruCache.get(cache, :test2)

    assert cache.queue == [:test2, :test, :test3]
    assert cache.values == %{test: :value, test2: :value2, test3: :value3}
  end

  test "put/3 evicts old values" do
    cache = LruCache.new(5)
    cache = LruCache.put(cache, :test, :value)
    cache = LruCache.put(cache, :test2, :value2)
    cache = LruCache.put(cache, :test3, :value3)
    cache = LruCache.put(cache, :test4, :value4)
    cache = LruCache.put(cache, :test5, :value5)

    assert cache.queue == [:test5, :test4, :test3, :test2, :test]

    assert cache.values == %{
             test: :value,
             test2: :value2,
             test3: :value3,
             test4: :value4,
             test5: :value5
           }

    cache = LruCache.put(cache, :test6, :value6)

    assert cache.queue  == [:test6, :test5, :test4, :test3, :test2]
    assert cache.values == %{ test2: :value2, test3: :value3, test4: :value4, test5: :value5, test6: :value6 }
  end

  test "put/3 and get/2 re-order and evict correctly" do
    cache = LruCache.new(5)
    cache = LruCache.put(cache, :test, :value)
    cache = LruCache.put(cache, :test2, :value2)
    cache = LruCache.put(cache, :test3, :value3)

    {:some, cache, value_a} = LruCache.get(cache, :test)

    assert value_a == :value
    assert cache.queue == [:test, :test3, :test2]
    assert cache.values == %{test: :value, test2: :value2, test3: :value3}

    {:some, cache, value_b} = LruCache.get(cache, :test2)

    assert value_b == :value2
    assert cache.queue == [:test2, :test, :test3]
    assert cache.values == %{test: :value, test2: :value2, test3: :value3}

    cache = LruCache.put(cache, :test4, :value4)
    cache = LruCache.put(cache, :test5, :value5)

    assert cache.queue == [:test5, :test4, :test2, :test, :test3]
    assert cache.values == %{ test: :value, test2: :value2, test3: :value3, test4: :value4, test5: :value5 }

    cache = LruCache.put(cache, :test6, :value6)

    assert cache.queue == [:test6, :test5, :test4, :test2, :test]
    assert cache.values == %{ test: :value, test2: :value2, test4: :value4, test5: :value5, test6: :value6 }
  end
end
