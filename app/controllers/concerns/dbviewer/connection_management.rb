module Dbviewer
  module ConnectionManagement
    extend ActiveSupport::Concern

    included do
      helper_method :current_connection_key, :available_connections if respond_to?(:helper_method)
    end

    # Get the current active connection key
    def current_connection_key
      key = session[:dbviewer_connection] || Dbviewer.configuration.current_connection
      return key.to_sym if key && Dbviewer.configuration.database_connections.key?(key.to_sym)

      first_key = Dbviewer.configuration.database_connections.keys.first
      if first_key
        session[:dbviewer_connection] = first_key
        return first_key
      end

      :default
    end

    # Set the current connection to use
    def switch_connection(connection_key)
      connection_key = connection_key.to_sym if connection_key.respond_to?(:to_sym)

      if connection_key && Dbviewer.configuration.database_connections.key?(connection_key)
        session[:dbviewer_connection] = connection_key
        # Clear the database manager to force it to be recreated with the new connection
        @database_manager = nil
        return true
      else
        # If the connection key doesn't exist, reset to default connection
        if Dbviewer.configuration.database_connections.key?(Dbviewer.configuration.current_connection)
          session[:dbviewer_connection] = Dbviewer.configuration.current_connection
          @database_manager = nil
          return true
        else
          # If even the default connection isn't valid, try the first available connection
          first_key = Dbviewer.configuration.database_connections.keys.first
          if first_key
            session[:dbviewer_connection] = first_key
            @database_manager = nil
            return true
          end
        end
      end

      false # Return false if we couldn't set a valid connection
    end

    # Get list of available connections
    def available_connections
      connections = Dbviewer.configuration.database_connections.map do |key, config|
        # Try to determine the adapter name if it's not already stored
        adapter_name = nil
        if config[:adapter_name].present?
          adapter_name = config[:adapter_name]
        elsif config[:connection].present?
          begin
            adapter_name = config[:connection].connection.adapter_name
          rescue => e
            Rails.logger.error("Error getting adapter name: #{e.message}")
          end
        end

        {
          key: key,
          name: config[:name] || key.to_s.humanize,
          adapter_name: adapter_name,
          current: key.to_sym == current_connection_key.to_sym
        }
      end

      # Ensure at least one connection is marked as current
      unless connections.any? { |c| c[:current] }
        # If no connection is current, mark the first one as current
        if connections.any?
          connections.first[:current] = true
          # Also update the session
          session[:dbviewer_connection] = connections.first[:key]
        end
      end

      connections
    end
  end
end
