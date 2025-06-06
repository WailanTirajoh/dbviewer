module Dbviewer
  module UiHelper
    # Dark mode helper methods

    # Returns the theme toggle icon based on the current theme
    def theme_toggle_icon
      '<i class="bi bi-moon"></i><i class="bi bi-sun"></i>'.html_safe
    end

    # Returns the aria label for the theme toggle button
    def theme_toggle_label
      "Toggle dark mode"
    end

    # Returns the appropriate background class for stat cards that adapts to dark mode
    def stat_card_bg_class
      "stat-card-bg"
    end

    # Helper method for code blocks background that adapts to dark mode
    def code_block_bg_class
      "sql-code-block"
    end

    # Render time grouping links
    def time_grouping_links(table_name, current_grouping)
      params = common_params

      content_tag(:div, class: "btn-group btn-group-sm", role: "group", 'aria-label': "Time grouping") do
        [
          link_to("Hourly", table_path(table_name, params.merge(time_group: "hourly")),
                 class: "btn btn-outline-primary #{current_grouping == 'hourly' ? 'active' : ''}"),
          link_to("Daily", table_path(table_name, params.merge(time_group: "daily")),
                 class: "btn btn-outline-primary #{current_grouping == 'daily' ? 'active' : ''}"),
          link_to("Weekly", table_path(table_name, params.merge(time_group: "weekly")),
                 class: "btn btn-outline-primary #{current_grouping == 'weekly' ? 'active' : ''}")
        ].join.html_safe
      end
    end
  end
end
