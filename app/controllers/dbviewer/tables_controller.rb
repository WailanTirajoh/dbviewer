module Dbviewer
  class TablesController < ApplicationController
    include Dbviewer::AccessControlValidation

    before_action :set_table_name, except: [ :index ]
    before_action :validate_table, only: [ :show, :query, :export_csv, :new_record, :create_record, :destroy_record ]
    before_action :set_query_filters, only: [ :show, :export_csv ]
    before_action :set_global_filters, only: [ :show, :export_csv ]

    def index
      @tables = @tables.map do |table|
        table.merge(record_count: fetch_table_record_count(table[:name]))
      end
    end

    def show
      query_params = Dbviewer::Datatable::QueryParams.new(
        page: @current_page,
        per_page: @per_page,
        order_by: @order_by,
        direction: @order_direction,
        column_filters: @column_filters.reject { |_, v| v.blank? }
      )
      datatable_data = fetch_datatable_data(@table_name, query_params)

      @total_count = datatable_data[:total_count]
      @records = datatable_data[:records]
      @total_pages = datatable_data[:total_pages]
      @columns = filter_accessible_columns(@table_name, datatable_data[:columns])
      @metadata = datatable_data[:metadata]
    end

    def new_record
      @table_columns = filter_accessible_columns(@table_name, database_manager.table_columns(@table_name))
      @metadata = database_manager.table_metadata(@table_name)
      @foreign_key_options = load_foreign_key_options(@metadata)

      render layout: false
    end

    def create_record
      model_class = database_manager.get_model_for(@table_name)
      record = model_class.new(record_params)

      if record.save
        render json: { message: "Record created successfully" }
      else
        render json: { errors: record.errors, messages: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def query
      all_columns = fetch_table_columns(@table_name)
      @columns = filter_accessible_columns(@table_name, all_columns)
      @query = prepare_query(@table_name, params[:query])

      if @query.present?
        begin
          validate_query_access(@query)
        rescue SecurityError => e
          flash[:alert] = e.message
          render :query and return
        end
      end

      @records = execute_query(@query)
    end

    def export_csv
      unless Dbviewer.configuration.enable_data_export
        flash[:alert] = "Data export is disabled in the configuration"
        redirect_to table_path(params[:id])
        return
      end

      query_params = Dbviewer::Datatable::QueryParams.new(
        page: @current_page,
        per_page: (params[:limit] || 10000).to_i,
        order_by: @order_by,
        direction: @order_direction,
        column_filters: @column_filters.reject { |_, v| v.blank? }
      )

      csv_data = export_table_to_csv(@table_name, query_params, params[:include_headers] != "0")
      filename = "#{@table_name}_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"

      send_data csv_data,
                type: "text/csv; charset=utf-8; header=present",
                disposition: "attachment; filename=#{filename}"
    end

    def destroy_record
      model_class = database_manager.get_model_for(@table_name)
      primary_key = database_manager.primary_key(@table_name) || "id"
      record = model_class.find_by(primary_key => params[:record_id])

      if record.nil?
        render json: { error: "Record not found" }, status: :not_found
        return
      end

      begin
        if record.destroy
          render json: { message: "Record deleted successfully" }, status: :ok
        else
          render json: { errors: record.errors.full_messages, message: "Failed to delete record" }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error("Error deleting record from #{@table_name}: #{e.message}")
        render json: { error: "Failed to delete record: #{e.message}" }, status: :internal_server_error
      end
    end

    private

    def record_params
      accessible_columns = filter_accessible_columns(@table_name, database_manager.table_columns(@table_name))

      permitted_fields = accessible_columns
        .reject { |col| %w[id created_at updated_at].include?(col[:name]) }
        .map { |col| col[:name].to_sym }

      params.require(:record).permit(*permitted_fields)
    end

    def set_table_name
      @table_name = params[:id]
    end

    def validate_table
      validate_table_access(@table_name)
    end

    def set_query_filters
      @current_page = [ 1, params[:page].to_i ].max
      @per_page = Dbviewer.configuration.per_page_options.include?(params[:per_page].to_i) ? params[:per_page].to_i : Dbviewer.configuration.default_per_page
      @order_by = params[:order_by].presence || determine_default_order_column
      @order_direction = %w[ASC DESC].include?(params[:order_direction].to_s.upcase) ? params[:order_direction].upcase : "DESC"
      @column_filters = params[:column_filters].presence ? params[:column_filters].to_enum.to_h : {}
    end

    def set_global_filters
      session[:creation_filter_start] = params[:creation_filter_start] if params[:creation_filter_start].present?
      session[:creation_filter_end] = params[:creation_filter_end] if params[:creation_filter_end].present?

      if params[:clear_creation_filter] == "true"
        session.delete(:creation_filter_start)
        session.delete(:creation_filter_end)
      end

      @creation_filter_start = session[:creation_filter_start]
      @creation_filter_end = session[:creation_filter_end]
      @column_filters ||= {}

      if has_timestamp_column?(@table_name) && (@creation_filter_start.present? || @creation_filter_end.present?)
        %w[created_at created_at_operator created_at_end].each { |key| @column_filters.delete(key) }

        if @creation_filter_start.present? && @creation_filter_end.present?
          @column_filters.merge!("created_at" => @creation_filter_start, "created_at_end" => @creation_filter_end)
        elsif @creation_filter_start.present?
          @column_filters.merge!("created_at" => @creation_filter_start, "created_at_operator" => "gte")
        elsif @creation_filter_end.present?
          @column_filters.merge!("created_at" => @creation_filter_end, "created_at_operator" => "lte")
        end
      end
    end

    def determine_default_order_column
      columns = @columns || fetch_table_columns(@table_name)
      column_names = columns.map { |col| col[:name] }

      Dbviewer.configuration.default_order_column.presence_in(column_names) ||
        database_manager.primary_key(@table_name) ||
        columns.first&.dig(:name)
    end

    def find_display_column(columns)
      column_names = columns.map { |c| c[:name] }
      # Common display columns to check for (TODO: next we can add this to configuration for better dev control)
      # If none found, fallback to first non-id column or id column
      # This ensures we have a sensible default for display purposes
      %w[name title label display_name username email description].find { |name| column_names.include?(name) } ||
        columns.find { |c| [ :string, :text ].include?(c[:type]) && c[:name] != "id" }&.[](:name) ||
        columns.find { |c| c[:name] != "id" }&.[](:name) || "id"
    end

    def load_foreign_key_options(metadata)
      options = {}
      metadata[:foreign_keys].each do |fk|
        foreign_table = fk[:to_table]
        foreign_key_column = fk[:primary_key] || "id"
        next unless access_control.table_accessible?(foreign_table)

        begin
          foreign_columns = database_manager.table_columns(foreign_table)
          display_column = find_display_column(foreign_columns)

          foreign_model = database_manager.get_model_for(foreign_table)
          records = foreign_model
                    .select([ foreign_key_column, display_column ].uniq)
                    .limit(100)
                    .order(display_column)
                    .map { |r| [ r[display_column].to_s, r[foreign_key_column] ] }

          options[fk[:column]] = records
        rescue => e
          Rails.logger.error("Error fetching foreign key options for #{foreign_table}: #{e.message}")
          options[fk[:column]] = []
        end
      end
      options
    end
  end
end
