module Dbviewer
  module Database
    # DynamicModelFactory creates and manages ActiveRecord models for database tables
    class DynamicModelFactory
      # Initialize with a connection, cache manager, and metadata manager
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param cache_manager [Dbviewer::Cache::Base] Cache manager instance
      def initialize(connection, cache_manager, metadata_manager)
        @connection = connection
        @cache_manager = cache_manager
        @metadata_manager = metadata_manager
      end

      # Get or create an ActiveRecord model for a table
      # @param table_name [String] Name of the table
      # @return [Class] ActiveRecord model class for the table
      def get_model_for(table_name)
        # Cache models for shorter time since they might need refreshing more frequently
        @cache_manager.fetch("model-#{table_name}", expires_in: 300) do
          find_or_create_model_for(table_name)
        end
      end

      private

      # Create a new ActiveRecord model for a table
      # @param table_name [String] Name of the table
      # @return [Class] ActiveRecord model class for the table
      def find_or_create_model_for(table_name)
        class_name = table_name.classify

        # Check if we can reuse an existing constant
        existing_model = handle_existing_constant(class_name, table_name)
        return existing_model if existing_model

        table_metadata = @metadata_manager.table_metadata(table_name)
        model = create_active_record_model(class_name, table_name, table_metadata)
        model.establish_connection(@connection.instance_variable_get(:@config))
        model
      end

      # Handle existing constant - check if we can reuse it or need to remove it
      # @param class_name [String] The constant name to check
      # @param table_name [String] The table name this model should represent
      # @return [Class, nil] Existing model if reusable, nil otherwise
      def handle_existing_constant(class_name, table_name)
        return nil unless Dbviewer.const_defined?(class_name, false)

        existing_model = Dbviewer.const_get(class_name)
        return existing_model if valid_model_for_table?(existing_model, table_name)

        # If it exists but isn't the right model, remove it first
        Dbviewer.send(:remove_const, class_name)
        nil
      end

      # Check if an existing model is valid for the given table
      # @param model [Class] The model class to validate
      # @param table_name [String] The expected table name
      # @return [Boolean] true if the model is valid for the table, false otherwise
      def valid_model_for_table?(model, table_name)
        model.respond_to?(:table_name) && model.table_name == table_name
      end

      # Create a new ActiveRecord model class for a table
      # @param class_name [String] The constant name for the model
      # @param table_name [String] The table name this model should represent
      # @return [Class] New ActiveRecord model class
      def create_active_record_model(class_name, table_name, table_metadata)
        Dbviewer.const_set(class_name, Class.new(ActiveRecord::Base) do
          self.table_name = table_name

          # Some tables might not have primary keys, so we handle that
          begin
            primary_key = connection.primary_key(table_name)
            self.primary_key = primary_key if primary_key.present?
          rescue
            self.primary_key = "id"
          end

          # Add validations from indexes
          table_metadata[:indexes].each do |index|
            next unless index[:unique] && index[:columns].present?

            columns = index[:columns]
            column = columns.first
            if columns.size == 1
              validates column, uniqueness: true
            elsif columns.size > 1
              # Validate composite uniqueness using `scope`
              validates column, uniqueness: { scope: columns[1..].map(&:to_sym) }
            end
          end
        end)
      end
    end
  end
end
