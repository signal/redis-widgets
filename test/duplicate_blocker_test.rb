require 'test_helper'
require 'redis-widgets/duplicate_blocker'

class DuplicateBlockerTest < ActiveSupport::TestCase
  def setup
    @blocker = Redis::Widgets::DuplicateBlocker.new('dups', 3)
  end

  test "requires a block" do
    assert_raise(ArgumentError) { @blocker.on_duplicate }
  end

  test "should call block when a duplicate is detected" do
    @blocker.on_duplicate('foo') { fail 'should not block' }

    blocked = false
    @blocker.on_duplicate('foo') { blocked = true }
    assert blocked

    blocked = false
    @blocker.on_duplicate('foo') { blocked = true }
    assert blocked
  end

  test "should not block different values" do
    @blocker.on_duplicate('foo') { fail 'should not block' }
    @blocker.on_duplicate('bar') { fail 'should not block' }
  end

  test "should allow multiple components for the duplicate check" do
    @blocker.on_duplicate('foo', 1) { fail 'should not block' }
    @blocker.on_duplicate('foo', 2) { fail 'should not block' }

    blocked = false
    @blocker.on_duplicate('foo', 1) { blocked = true }
    assert blocked
  end

  test "should block messages within the time window" do
    tomorrow = 1.day.from_now
    three_days = 3.days.from_now
    next_week = 1.week.from_now

    @blocker.on_duplicate('foo', 1) { fail 'should not block' }

    Time.stubs(:now).returns(tomorrow)
    blocked = false
    @blocker.on_duplicate('foo', 1) { blocked = true }
    assert blocked
    
    Time.expects(:now).returns(three_days)
    @blocker.on_duplicate('foo', 1) { fail 'should not block' }

    Time.expects(:now).returns(next_week)
    @blocker.on_duplicate('foo', 1) { fail 'should not block' }
  end

  test "should block messages when servers times are not completely in sync" do
    now = Time.now
    tomorrow = 1.day.from_now

    # Server A is a bit ahead
    Time.stubs(:now).returns(tomorrow)
    @blocker.on_duplicate('foo', 1) { fail 'should not block' }

    # Server B should still stop the dup
    Time.stubs(:now).returns(now)
    blocked = false
    @blocker.on_duplicate('foo', 1) { blocked = true }
    assert blocked
  end

  test "should only use 20 bytes to store the duplicate digest" do
    @blocker.on_duplicate('foo', 1) { }

    expected_digest = Digest::SHA1.digest(['foo', 1].join('|'))
    assert Redis.current.sismember("dups-#{Time.now.utc.to_date}", expected_digest)
  end

  test "duplicate? should correctly identify duplicates" do
    assert !@blocker.duplicate?('foo')
    assert @blocker.duplicate?('foo')
    assert @blocker.duplicate?('foo')
    
    assert !@blocker.duplicate?('bar')
    assert !@blocker.duplicate?('bar', 1)
  end

  test "size returns the number of entries in the relevant Redis sets" do
    assert_equal 0, @blocker.size
    @blocker.duplicate?('foo')
    @blocker.duplicate?('foo') # dup
    @blocker.duplicate?('bar')
    assert_equal 2, @blocker.size
  end

  test "each day's set should expire outside the blocking window" do
    @blocker.duplicate?('foo')
    assert_in_delta 4.days.to_i, Redis.current.ttl("dups-#{Time.now.utc.to_date}"), 10
  end
end
