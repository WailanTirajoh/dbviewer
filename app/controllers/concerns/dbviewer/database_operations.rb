module Dbviewer
  module DatabaseOperations
    extend ActiveSupport::Concern

    include ConnectionManagement
    include DatabaseInformation
    include TableOperations
    include RelationshipManagement
    include QueryOperations
    include DataExport

    # -- Database Managers --

    # Initialize the database manager with the current connection
    def database_manager
      @database_manager = ::Dbviewer::Database::Manager.new(current_connection_key)
    end

    # Initialize the table query operations manager
    # This gives direct access to table query operations when needed
    def table_query_operations
      @table_query_operations ||= database_manager.table_query_operations
    end
  end
end
