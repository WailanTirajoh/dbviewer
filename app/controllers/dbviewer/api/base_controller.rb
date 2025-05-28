module Dbviewer
  module Api
    class BaseController < ApplicationController
      # Skip setting the tables instance variable for API endpoints since we don't need it
      skip_before_action :set_tables

      # Common API response handling for errors
      def render_error(error_message, status = :internal_server_error)
        Rails.logger.error(error_message)
        render json: { error: error_message }, status: status
      end

      # Common API response handling for success
      def render_success(data)
        render json: data
      end
    end
  end
end
