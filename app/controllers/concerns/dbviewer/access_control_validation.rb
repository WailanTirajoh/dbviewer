module Dbviewer
  module AccessControlValidation
    extend ActiveSupport::Concern

    private

    def validate_table_access(table_name)
      return unless table_name.present?

      unless access_control.table_accessible?(table_name)
        Rails.logger.warn "DBViewer: Access denied for table '#{table_name}'"
        flash[:alert] = access_control.access_violation_message(table_name)
        redirect_to tables_path and return
      else
        Rails.logger.info "DBViewer: Access granted for table '#{table_name}'"
      end
    end

    def validate_query_access(sql)
      unless access_control.validate_query_table_access(sql)
        raise SecurityError, "Query contains references to inaccessible tables"
      end
    end
  end
end
