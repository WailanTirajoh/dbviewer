module Dbviewer
  # QueryStorage is an abstract base class that defines the interface for query storage backends
  class QueryStorage
    # Initialize the storage backend
    def initialize
      raise NotImplementedError, "#{self.class} is an abstract class and cannot be instantiated directly"
    end

    # Get all stored queries
    def all
      raise NotImplementedError, "#{self.class}#all must be implemented by a subclass"
    end

    # Add a new query to the storage
    def add(query)
      raise NotImplementedError, "#{self.class}#add must be implemented by a subclass"
    end

    # Clear all stored queries
    def clear
      raise NotImplementedError, "#{self.class}#clear must be implemented by a subclass"
    end

    # Filter the queries based on provided criteria
    def filter(limit:, table_filter:, request_id:, min_duration:)
      raise NotImplementedError, "#{self.class}#filter must be implemented by a subclass"
    end
  end
end
