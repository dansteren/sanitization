# Sanitization

Sanitization makes it easy to store slightly cleaner strings to your database.

## Features

- White space stripping
- White space squishing (multiple consecutive spaces combined into one)
- Blank string to nil (if database column supports it)
- Change casing (ie. upcase, downcase, titlecase, etc)
- Global substitution of regex (gsub)
- Removing a specified pattern
- Rounding decimal places
- Truncating large strings
- Before and after callbacks
- User defined Sanitizers

## Installation

```sh
bundle add sanitization
```

## Usage

```ruby
# Custom Sanitizer. See use down below with attribute 4
class SsnSanitizer < Sanitization::EachSanitizer
  # Strips all dashes from a provided string.
  #
  # @param record [ActiveRecord] the record being sanitized
  # @param attribute [Symbol] the name of the attribute being sanitized
  # @param value [Object] the value being sanitized
  #
  # @return sanitized_value [Object] the sanitized value to be stored in the attribute
  def sanitize_each(record, attribute, value)
    value.gsub(/-/, '')
  end
end

class MyModel < ActiveRecord::Base
  # Single sanitizer
  sanitizes :attribute_1, strip: true

  # Using `sanitize` instead of `sanitizes
  sanitize :attribute_2, strip: true

  # Multiple sanitizers
  sanitizes :attribute_3,
    case: :up|:down|:camel|:snake|:title|:pascal, # Converts to different cases
    gsub: { pattern: /[aeiou]/, replacement: '*' }, # Replaces all occurences of a pattern
    nullify: true, # Converts empty/blank strings to null
    remove: /[aeiou]/, # Removes all occurences of a pattern
    round: 2, # Rounds a float to the given number of decimal places
    squish: true, # Removes surrounding and internal consecutive whitespace characters
    strip: true, # Removes surrounding whitespace
    truncate: 50, # Truncates values to a given length

  sanitizes :attribute_4, ssn: true, # Custom sanitizer declared by SsnSanitizer

  # Supports lifecycle hooks
  before_sanitization :pre_log
  after_sanitization  :post_log

  def pre_log
    puts "About to start running sanitization..."
  end

  def post_log
    puts "Finished running sanitization!"
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
