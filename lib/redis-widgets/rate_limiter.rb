require 'redis'
require 'active_support/core_ext'

class Redis
  module Widgets
    # A class that uses Redis to limit . We track duplicates
    # using a digest of the components that the calling code supplies us.
    class RateLimiter
      attr_reader :name, :seconds, :number_of_requests

      # Initializes the rate limiter.
      #
      # name:
      #   The name of this limiter. This value is used as part of the Redis keys.
      # number_of_requests:
      #   The number of requests allowed per seconds
      # seconds:
      #   The number of seconds that the limiter should be enforced for.
      def initialize(name, number_of_requests, seconds)
        @name = name
        @seconds = seconds
        @number_of_requests = number_of_requests
        raise ArgumentError, 'number_of_requests must be greater than 0' unless @number_of_requests > 0
        raise ArgumentError, 'seconds must be greater than 0' unless @seconds > 0
      end

      # Returns false if the components supplied have been seen
      # @number_of_request per @seconds. If true is returned, the components are tracked in
      # Redis until they either expire or reach the limit returning true.
      def allowed?(*components)
        keyname = sname(components.join(':'))

        current = Redis.current.llen(keyname)
        if current.present? && current.to_i > (number_of_requests - 1)
          return false
        else
          if !Redis.current.exists(keyname)
            Redis.current.multi do
              Redis.current.rpush(keyname, keyname)
              Redis.current.expire(keyname, seconds)
            end
          else
            Redis.current.rpushx(keyname, keyname)
          end
          return true
        end
      end

      # Yields to a block if the components supplied have reached
      # their limit found in the Redis sets
      def on_limit_reached(*components)
        raise ArgumentError, 'must supply a block' unless block_given?

        yield if !allowed?(*components)
      end

      private

      def sname(c)
        "#{@name}:#{c}"
      end
    end
  end
end
