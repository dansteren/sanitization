module Sanitization
  class EachSanitizer
    # Override this method in subclasses with the sanitization logic
    def sanitize_each(record, attribute, value)
      raise NotImplementedError, "Subclasses must implement a sanitize_each(record, attribute, value) method"
    end
  end
end
