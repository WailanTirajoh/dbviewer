module Dbviewer
  module DisabledStateValidation
    extend ActiveSupport::Concern

    included do
      before_action :check_if_dbviewer_disabled
    end

    private

    # Check if DBViewer is completely disabled
    def check_if_dbviewer_disabled
      if Dbviewer.configuration.disabled
        Rails.logger.info "DBViewer: Access denied - DBViewer is disabled"
        render plain: "Not Found", status: :not_found and return
      end
    end
  end
end
