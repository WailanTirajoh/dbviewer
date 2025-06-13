module Dbviewer
  module Cache
    # Base handles caching concerns for the DatabaseManager
    # It provides an abstraction layer for managing caches efficiently
    class Base
      # Initialize the cache manager
      # @param cache_expiry [Integer] Cache expiration time in seconds (default: 300)
      def initialize(cache_expiry = 300)
        @cache_expiry = cache_expiry
        @unified_cache = {}
        @cache_last_reset = Time.now
      end

      # Fetch data from cache or execute block if not found/expired
      # @param key [String] Cache key
      # @param options [Hash] Options for the cache entry
      # @option options [Integer] :expires_in Custom expiry time in seconds
      # @yield Block to execute if cache miss or expired
      # @return [Object] Cached value or result of block execution
      def fetch(key, options = {}, &block)
        raise NotImplementedError, "#{self.class}#fetch must be implemented by a subclass"
      end

      # Delete a specific cache entry by key
      # @param key [String] Cache key to delete
      # @return [Object, nil] The deleted value or nil if not found
      def delete(key)
        raise NotImplementedError, "#{self.class}#delete must be implemented by a subclass"
      end
    end
  end
end
