module Dbviewer
  class ApplicationController < ActionController::Base
    include Dbviewer::DatabaseOperations

    before_action :ensure_development_environment

    private

    def ensure_development_environment
      unless Rails.env.development? || Rails.env.test? || params[:override_env_check] == ENV["DBVIEWER_PRODUCTION_ACCESS_KEY"]
        render plain: "DBViewer is only available in development and test environments for security reasons.", status: :forbidden
      end
    end
  end
end
