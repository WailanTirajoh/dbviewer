module Dbviewer
  module DatabaseOperations
    extend ActiveSupport::Concern

    include ConnectionManagement
    include DataExport
    include DatabaseInformation
    include DatatableOperations
    include QueryOperations
    include RelationshipManagement
    include TableOperations

    def database_manager
      @database_manager = ::Dbviewer::Database::Manager.new(current_connection_key)
    end

    def table_query_operations
      @table_query_operations ||= database_manager.table_query_operations
    end
  end
end
