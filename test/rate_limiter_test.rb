require 'test_helper'
require 'redis-widgets/rate_limiter'

class RateLimiterTest < ActiveSupport::TestCase
  def setup
    @limiter = Redis::Widgets::RateLimiter.new('limit', 2, 5)
  end

  def test_requires_a_block
    assert_raise(ArgumentError) { @limiter.on_limit_reached }
  end

  def test_call_block_when_a_rate_block_is_detected
    @limiter.on_limit_reached('foo1') { fail 'should not block' }
    @limiter.on_limit_reached('foo1') { fail 'should not block' }

    blocked = false
    @limiter.on_limit_reached('foo1') { blocked = true }
    assert blocked

    blocked = false
    @limiter.on_limit_reached('foo1') { blocked = true }
    assert blocked
  end

  def test_dont_block_different_values
    @limiter.on_limit_reached('foo', "bar", "bazz") { fail 'should not block' }
    @limiter.on_limit_reached('bar') { fail 'should not block' }
    @limiter.on_limit_reached('foo', "bar") { fail 'should not block' }
    @limiter.on_limit_reached('bar2') { fail 'should not block' }
  end

  def test_allow_multiple_components_for_the_check
    @limiter.on_limit_reached('foo', 1) { fail 'should not block' }
    @limiter.on_limit_reached('foo', 1) { fail 'should not block' }
    @limiter.on_limit_reached('foo', 2) { fail 'should not block' }

    blocked = false
    @limiter.on_limit_reached('foo', 1) { blocked = true }
    assert blocked
  end

  def block_messages_within_the_time_window

    @limiter.on_limit_reached('foo', 1) { fail 'should not block' }
    @limiter.on_limit_reached('foo', 1) { fail 'should not block' }

    blocked = false
    @limiter.on_limit_reached('foo', 1) { blocked = true }
    assert blocked
    sleep 5
    @limiter.on_limit_reached('foo', 1) { fail 'should not block' }
    @limiter.on_limit_reached('foo', 1) { fail 'should not block' }
  end

  def test_allowed_should_correctly_identify_limted_requests
    assert @limiter.allowed?('foo')
    sleep 1
    assert @limiter.allowed?('foo')
    sleep 1
    assert !@limiter.allowed?('foo')
    assert !@limiter.allowed?('foo')
    sleep 3
    assert @limiter.allowed?('foo')
    assert @limiter.allowed?('bar')
    assert @limiter.allowed?('bar')
    assert !@limiter.allowed?('bar')
    assert @limiter.allowed?('bar', 1)
  end
end
