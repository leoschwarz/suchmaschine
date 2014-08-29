require 'minitest/autorun'
require 'minitest/benchmark'
require_relative '../lib/task_queue/task_queue.rb'

class TestTaskQueue < MiniTest::Unit::TestCase
  def setup
    @queue = TaskQueue.new
    load_fixture_small
  end
  
  def test_size
    assert_equal 0, @queue.size
    @queue.insert(@url_fixture_small.first)
    assert_equal 1, @queue.size 
  end
  
  def test_insert_and_fetch_basic
    @url_fixture_small.each{ |url| @queue.insert url }
    actual = _fetch_all(@queue)
    assert_equal @url_fixture_small.sort, actual.sort
  end
  
  def test_insert_and_fetch_priority_order
    expected = @url_fixture_small.shuffle
    pairs = expected.each_with_index.map{|v,i| {url: expected[i], priority: @url_fixture_small.length-i}}
    pairs.shuffle.each do |pair|
      @queue.insert(pair[:url], pair[:priority])
    end
    
    assert_equal expected, _fetch_all(@queue)
  end
  
  def test_increase_priority
    @url_fixture_small.shuffle.each {|url| @queue.insert url}
    @queue.increase_priority(@url_fixture_small[2], 2)
    @queue.increase_priority(@url_fixture_small[4], 1)
    expected = @url_fixture_small.values_at 2, 4
    assert_equal expected, _fetch_n(@queue, 2)
  end
  
  def test_increase_priority_on_double_insert
    @url_fixture_small.shuffle.each {|url| @queue.insert url}
    index = rand(0...@url_fixture_small.size)
    @queue.insert @url_fixture_small[index]
    expected = [@url_fixture_small[index]]
    assert_equal expected, _fetch_n(@queue, 1)
  end
  
  def self.bench_range
    [100,1000,10000,100000,1000000]
  end
  
  def bench_insert_url
    load_fixture_big
    assert_performance proc{} do |n|
      q = TaskQueue.new
      (0...n).each{|i| q.insert(@url_fixture_big[i])}
      q = nil
    end
  end
  
  def bench_fetch_url
    load_fixture_big
    queues = {}
    TestTaskQueue.bench_range.each do |n|
      q = queues[n] = TaskQueue.new
      (0...n).each{|i| q.insert(@url_fixture_big[i])}
    end
    
    assert_performance proc{} do |n|
      n.times{ queues[n].fetch }
    end
  end
  
  private
  def load_fixture_small
    @url_fixture_small = (1..10).map{|i| i.to_s}
    #@url_fixture_small = (1..10).map{|i| "http://www.example.com/page/#{i}.html"}
  end
  
  def load_fixture_big
    @url_fixture_big = (1..1000000).map{|i| i.to_s}
    #@url_fixture_big   = (1..1000).map{|i| "http://www.example.com/page/#{i}.html"}
  end
  
  def _fetch_n(queue, n)
    fetched = []
    n.times{ fetched << queue.fetch }
    fetched
  end
  
  def _fetch_all(queue)
    fetched = []
    while queue.size > 0
      fetched << queue.fetch
    end
    fetched
  end
end
