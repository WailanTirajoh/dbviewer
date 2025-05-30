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

    # GET /dbviewer/connections/new
    def new
      respond_to do |format|
        format.html
        format.js
      end
    end
    
    # POST /dbviewer/connections
    def create
      key = params[:connection_key].to_s.strip.gsub(/\s+/, '_').downcase.to_sym
      name = params[:connection_name].to_s.strip
      connection_class = params[:connection_class].to_s.strip
      
      # Basic validation
      if key.blank? || name.blank? || connection_class.blank?
        flash[:alert] = "All fields are required"
        return redirect_to connections_path
      end
      
      # Check if the connection key is already used
      if Dbviewer.configuration.database_connections.key?(key)
        flash[:alert] = "Connection key '#{key}' is already in use"
        return redirect_to connections_path
      end
      
      # Try to add the connection
      success, error = Dbviewer.configuration.add_connection(key, {
        connection_class: connection_class,
        name: name
      })
      
      if success
        flash[:notice] = "Connection '#{name}' added successfully"
      else
        flash[:alert] = "Failed to add connection: #{error || 'Invalid connection class'}"
      end
      
      redirect_to connections_path
    end

    # POST /dbviewer/connections/:id
    def update
      connection_key = params[:id]
      
      if switch_connection(connection_key)
        # Safely get the connection name
        connection_config = Dbviewer.configuration.database_connections[connection_key.to_sym]
        connection_name = connection_config && connection_config[:name] ? connection_config[:name] : "selected"
        
        respond_to do |format|
          format.html { redirect_to dashboard_path, notice: "Switched to #{connection_name} database." }
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
    
    # DELETE /dbviewer/connections/:id
    def destroy
      key = params[:id].to_sym
      
      if Dbviewer.configuration.remove_connection(key)
        flash[:notice] = "Connection removed successfully"
      else
        flash[:alert] = "Cannot remove this connection"
      end
      
      redirect_to connections_path
    end
  end
end
