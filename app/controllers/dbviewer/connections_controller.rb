module Dbviewer
  class ConnectionsController < ApplicationController
    # GET /dbviewer/connections
    def index
      @connections = available_connections

      respond_to do |format|
        format.html
        format.json { render json: @connections }
      end
    end

    # POST /dbviewer/connections/:id
    def update
      connection_key = params[:id]

      if switch_connection(connection_key)
        # Safely get the connection name
        connection_config = Dbviewer.configuration.database_connections[connection_key.to_sym]
        connection_name = connection_config && connection_config[:name] ? connection_config[:name] : "selected"

        respond_to do |format|
          format.html { redirect_to root_path, notice: "Switched to #{connection_name} database." }
          format.json { render json: { success: true, current: connection_key } }
        end
      else
        # Handle the case where switching failed
        respond_to do |format|
          format.html { redirect_to connections_path, alert: "Failed to switch connection. The connection may be invalid." }
          format.json { render json: { success: false, error: "Invalid connection" }, status: :unprocessable_entity }
        end
      end
    end
  end
end
