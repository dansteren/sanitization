module Sanitization
  class Sanitizer
    # Override this method in subclasses with the sanitization logic
    #
    # @param record [ActiveRecord] the record being sanitized
    def sanitize(record)
      raise NotImplementedError, "Subclasses must implement a sanitize(record) method"
    end
  end
end
