module Dbviewer
  module Api
    class ConnectionsController < ApplicationController
      # GET /dbviewer/api/connections/:id/test
      # Test if a connection is valid
      def test
        connection_key = params[:id].to_sym
        connection_config = Dbviewer.configuration.database_connections[connection_key]
        
        if connection_config.nil?
          return render json: { success: false, error: "Connection not found" }
        end
        
        begin
          if connection_config[:connection].present?
            connection_class = connection_config[:connection]
          elsif connection_config[:connection_class].present?
            connection_class = connection_config[:connection_class].constantize
          else
            return render json: { success: false, error: "No connection class specified" }
          end
          
          # Test the connection
          adapter_name = connection_class.connection.adapter_name
          tables_count = connection_class.connection.tables.count
          
          render json: { 
            success: true, 
            adapter_name: adapter_name,
            tables_count: tables_count,
            message: "Connected successfully to #{adapter_name} database with #{tables_count} tables"
          }
        rescue => e
          render json: { 
            success: false, 
            error: e.message 
          }
        end
      end
    end
  end
end
