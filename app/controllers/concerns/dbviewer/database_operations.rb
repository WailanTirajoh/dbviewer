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

    def access_control
      @access_control ||= Dbviewer::Security::AccessControl.new
    end

    def filter_accessible_tables(tables)
      access_control.filter_accessible_tables(tables)
    end

    def filter_accessible_columns(table_name, columns)
      access_control.filter_accessible_columns(table_name, columns)
    end
  end
end
