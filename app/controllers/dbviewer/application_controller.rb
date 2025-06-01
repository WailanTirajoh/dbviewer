module Dbviewer
  class ApplicationController < ActionController::Base
    include Dbviewer::DatabaseOperations

    before_action :authenticate_with_basic_auth
    before_action :set_tables

    private

    def authenticate_with_basic_auth
      return unless Dbviewer.configuration.admin_credentials.present?

      credentials = Dbviewer.configuration.admin_credentials
      authenticate_or_request_with_http_basic("DBViewer Authentication") do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, credentials[:username]) &
        ActiveSupport::SecurityUtils.secure_compare(password, credentials[:password])
      end
    end

    def set_tables
      @tables = fetch_tables
    end
  end
end
