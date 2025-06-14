# frozen_string_literal: true

module Dbviewer
  module Query
    # Handles ActiveSupport::Notifications subscription for SQL query monitoring
    # Only active in development environment to capture and log SQL queries
    class NotificationSubscriber
      class << self
        # Subscribe to SQL notifications if in development environment
        def subscribe
          return unless Rails.env.development?

          ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
            process_notification(*args)
          end
        end

        private

        # Process a single SQL notification event
        # @param args [Array] Notification arguments from ActiveSupport::Notifications
        def process_notification(*args)
          event = ActiveSupport::Notifications::Event.new(*args)
          Dbviewer::Query::Logger.instance.add(event)
        end

        # Determine if this query should be skipped (internal DBViewer queries)
        # @param event [ActiveSupport::Notifications::Event] The notification event
        # @return [Boolean] True if the query should be skipped
        def skip_internal_query?(event)
          caller_locations = caller_locations(1)
          return false unless caller_locations

          excluded_caller_locations = caller_locations.filter do |caller_location|
            !caller_location.path.include?("lib/dbviewer/query/notification_subscriber.rb")
          end

          excluded_caller_locations.any? { |location| location.path.include?("dbviewer") }
        end
      end
    end
  end
end
