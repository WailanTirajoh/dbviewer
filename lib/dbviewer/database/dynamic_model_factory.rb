module Dbviewer
  module Database
    # DynamicModelFactory creates and manages ActiveRecord models for database tables
    class DynamicModelFactory
      # Initialize with a connection and cache manager
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param cache_manager [Dbviewer::Database::CacheManager] Cache manager instance
      def initialize(connection, cache_manager)
        @connection = connection
        @cache_manager = cache_manager
      end

      # Get or create an ActiveRecord model for a table
      # @param table_name [String] Name of the table
      # @return [Class] ActiveRecord model class for the table
      def get_model_for(table_name)
        cached_model = @cache_manager.get_model(table_name)
        return cached_model if cached_model

        model = create_model_for(table_name)
        @cache_manager.store_model(table_name, model)
        model
      end

      private

      # Create a new ActiveRecord model for a table
      # @param table_name [String] Name of the table
      # @return [Class] ActiveRecord model class for the table
      def create_model_for(table_name)
        model = Dbviewer.const_set(table_name.classify, Class.new(ActiveRecord::Base) do
          self.table_name = table_name

          # Some tables might not have primary keys, so we handle that
          begin
            primary_key = connection.primary_key(table_name)
            self.primary_key = primary_key if primary_key.present?
          rescue
            self.primary_key = "id"
          end

          # Disable STI
          self.inheritance_column = :_type_disabled

          # Disable timestamps for better compatibility
          self.record_timestamps = false
        end)

        model.establish_connection(@connection.instance_variable_get(:@config))

        model
      end
    end
  end
end
