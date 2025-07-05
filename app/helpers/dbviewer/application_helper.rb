module Dbviewer
  module ApplicationHelper
    # Include all the helper modules organized by logical concerns
    include DatabaseHelper
    include FormattingHelper

    include DatatableUiHelper
    include DatatableUiFilterHelper
    include DatatableUiFormHelper
    include DatatableUiPaginationHelper
    include DatatableUiSortingHelper
    include DatatableUiTableHelper
    include NavigationHelper
    include UiHelper
  end
end
