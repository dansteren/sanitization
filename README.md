# Sanitization

Sanitization makes it easy to store slightly cleaner strings to your database.

### Features (all optional):

- White space stripping
- White space collapsing (multiple consecutive spaces combined into one)
- Empty string to nil (if database column supports it)
- Change casing (ie. upcase, downcase, titlecase, etc)

### Defaults

- Leading & training white spaces are stripped (`strip: true`)
- All spaces are collapsed (`collapse: true`)
- All String columns are sanitized (`only: nil, except: nil`)
- Columns of type `text` are not sanitized (`include_text_type: false`)
- Casing remains unchanged (`case: nil`)


## Installation

```sh
bundle add sanitization
```

## Usage

```ruby
# Default settings for all strings
class Person < ApplicationModel
  sanitization
  # is equivalent to:
  sanitization strip: true, collapse: true, include_text_type: false
end

# Default settings for all strings, except a specific column
class Person < ApplicationModel
  sanitization except: :alias
end

# Default settings + titlecase for specific columns
class Person < ApplicationModel
  sanitization only: [:first_name, :last_name], case: :title
end

# Complex example. All these lines could be used in combination.
class Person
  # Apply default settings and `titlecase` to all string columns, except `description`.
  sanitization case: :title, except: :description

  # Keep previous settings, but specify `upcase` for 2 columns.
  sanitization only: [:first_name, :last_name], case: :up

  # Keep previous settings, but specify `downcase` for a single column.
  sanitization only: :email, case: :downcase

  # Apply default settings to column `description`, of type `text`. By default, `text` type is NOT sanitized.
  sanitization only: :description, include_text_type: true

  # Disable collapsing for `do_not_collapse`.
  sanitization only: :do_not_collapse, collapse: false

  # Sanitize with a custom casing method named `leetcase` for the `133t` column.
  sanitization only: '1337', case: :leet
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).