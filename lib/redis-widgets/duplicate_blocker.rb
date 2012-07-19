require 'redis'
require 'digest/sha1'
require 'active_support/core_ext'

class Redis
  module Widgets
    # A class that uses Redis to watch for duplicate messages. We track duplicates
    # using a digest of the components that the calling code supplies us.
    class DuplicateBlocker
      attr_reader :name, :days

      # Initializes the duplicate blocker.
      #
      # name:
      #   The name of this blocker. This value is used as part of the Redis keys.
      # days:
      #   The number of days that the block should be enforced for.
      def initialize(name, days)
        @name = name
        @days = days

        raise ArgumentError, 'days must be greater than 0' unless @days > 0
      end

      # Returns true if the components supplied have already been seen before. If
      # false is returned, the components are tracked in Redis so the next call
      # will return true.
      def duplicate?(*components)
        digest = Digest::SHA1.digest(components.join('|'))

        today_utc = Time.now.utc.to_date

        already_seen = snames_to_check(today_utc).any? {|check_sname| Redis.current.sismember(check_sname, digest) }
        return true if already_seen

        if Redis.current.sadd(sname(today_utc), digest)
          Redis.current.expireat(sname(today_utc), (days+1).days.from_now.to_i)
          return false
        else
          return true
        end
      end

      # Yields to a block if the components supplied are found in the Redis sets
      # that are tracking duplicates.
      def on_duplicate(*components)
        raise ArgumentError, 'must supply a block' unless block_given?

        yield if duplicate?(*components)
      end

      def size
        today_utc = Time.now.utc.to_date
        [sname(today_utc), *snames_to_check(today_utc)].inject(0) do |sum, set_name|
          sum + Redis.current.scard(set_name)
        end
      end

      private
      # Returns that names of the sets that are the configure number of the days in
      # the past, as well as 1 in the future in case the server times are slightly
      # off.
      def snames_to_check(today_utc)
        (1...days).map {|x| sname(today_utc - x) } + [sname(today_utc + 1)]
      end

      def sname(date_utc)
        "#{@name}-#{date_utc}"
      end
    end
  end
end
