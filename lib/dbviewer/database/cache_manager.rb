module Dbviewer
  module Database
    # CacheManager handles caching concerns for the DatabaseManager
    # It provides an abstraction layer for managing caches efficiently
    class CacheManager
      # Initialize the cache manager
      # @param config [Dbviewer::Configuration] Configuration object
      def initialize(config = nil)
        @config = config || Dbviewer.configuration
        @dynamic_models = {}
        @table_columns_cache = {}
        @table_metadata_cache = {}
        @cache_last_reset = Time.now
      end

      # Get a model from cache or return nil
      # @param table_name [String] Name of the table
      # @return [Class, nil] The cached model or nil if not found
      def get_model(table_name)
        @dynamic_models[table_name]
      end

      # Store a model in the cache
      # @param table_name [String] Name of the table
      # @param model [Class] ActiveRecord model class
      def store_model(table_name, model)
        @dynamic_models[table_name] = model
      end

      # Get column information from cache
      # @param table_name [String] Name of the table
      # @return [Array<Hash>, nil] The cached column information or nil if not found
      def get_columns(table_name)
        @table_columns_cache[table_name]
      end

      # Store column information in cache
      # @param table_name [String] Name of the table
      # @param columns [Array<Hash>] Column information
      def store_columns(table_name, columns)
        @table_columns_cache[table_name] = columns
      end

      # Get table metadata from cache
      # @param table_name [String] Name of the table
      # @return [Hash, nil] The cached metadata or nil if not found
      def get_metadata(table_name)
        @table_metadata_cache[table_name]
      end

      # Store table metadata in cache
      # @param table_name [String] Name of the table
      # @param metadata [Hash] Table metadata
      def store_metadata(table_name, metadata)
        @table_metadata_cache[table_name] = metadata
      end

      # Reset caches if they've been around too long
      def reset_if_needed
        cache_expiry = @config.cache_expiry || 300

        if Time.now - @cache_last_reset > cache_expiry
          @table_columns_cache = {}
          @table_metadata_cache = {}
          @cache_last_reset = Time.now
          Rails.logger.debug("[DBViewer] Cache reset due to expiry after #{cache_expiry} seconds")
        end
      end

      # Clear all caches - useful when schema changes are detected
      def clear_all
        @dynamic_models = {}
        @table_columns_cache = {}
        @table_metadata_cache = {}
        @cache_last_reset = Time.now
        Rails.logger.debug("[DBViewer] All caches cleared")
      end
    end
  end
end
