module Dbviewer
  module ApplicationHelper
    # Include all the helper modules organized by logical concerns
    include DatabaseHelper
    include FilterHelper
    include FormattingHelper
    include PaginationHelper
    include SortingHelper
    include TableRenderingHelper
    include NavigationHelper
    include UiHelper
  end
end
