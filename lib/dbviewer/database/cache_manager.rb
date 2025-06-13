module Dbviewer
  module Database
    # CacheManager handles caching concerns for the DatabaseManager
    # It provides an abstraction layer for managing caches efficiently
    class CacheManager
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
        cache_entry = @unified_cache[key]
        custom_expiry = options[:expires_in] || @cache_expiry
        return cache_entry[:value] if cache_entry && !cache_expired?(cache_entry, custom_expiry)

        result = block.call
        @unified_cache[key] = {
          value: result,
          created_at: Time.now
        }
        result
      end

      # Delete a specific cache entry by key
      # @param key [String] Cache key to delete
      # @return [Object, nil] The deleted value or nil if not found
      def delete(key)
        deleted_entry = @unified_cache.delete(key)
        deleted_entry&.fetch(:value)
      end

      private

      # Check if a cache entry is expired
      # @param cache_entry [Hash] Cache entry with :created_at timestamp
      # @param expiry_time [Integer] Expiry time in seconds
      # @return [Boolean] True if expired, false otherwise
      def cache_expired?(cache_entry, expiry_time)
        Time.now - cache_entry[:created_at] > expiry_time
      end
    end
  end
end
