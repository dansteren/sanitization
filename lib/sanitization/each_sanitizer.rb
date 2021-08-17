module Sanitization
  class EachSanitizer
    # Override this method in subclasses with the sanitization logic
    #
    # @param record [ActiveRecord] the record being sanitized
    # @param attribute [Symbol] the name of the attribute being sanitized
    # @param value [Object] the value being sanitized
    #
    # @return sanitized_value [Object] the sanitized value to be stored in the attribute
    def sanitize_each(record, attribute, value)
      raise NotImplementedError, "Subclasses must implement a sanitize_each(record, attribute, value) method"
    end
  end
end
