module Dbviewer
  module NavigationHelper
    # Helper method to determine if current controller and action match
    def active_nav_class(controller_name, action_name = nil)
      current_controller = params[:controller].split("/").last
      active = current_controller == controller_name

      if action_name.present?
        active = active && params[:action] == action_name
      end

      active ? "active" : ""
    end

    # Helper for highlighting dashboard link
    def dashboard_nav_class
      active_nav_class("home")
    end

    # Helper for highlighting tables link
    def tables_nav_class
      active_nav_class("tables")
    end

    # Helper for highlighting ERD link
    def erd_nav_class
      active_nav_class("entity_relationship_diagrams")
    end

    # Helper for highlighting SQL Logs link
    def logs_nav_class
      active_nav_class("logs")
    end
  end
end
