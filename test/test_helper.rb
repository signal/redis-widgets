require 'rubygems'
require 'bundler/setup'

require 'test/unit'
require 'active_support'

require 'mocha/setup'

ENV["REDIS_URL"] ||= "redis://127.0.0.1:6379/10"

class ActiveSupport::TestCase
  setup :clear_redis

  def clear_redis
    Redis.current.flushdb
  end
end
