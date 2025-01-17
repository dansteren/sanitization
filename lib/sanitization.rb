require "sanitization/version"
require "sanitization/each_sanitizer"
require "sanitization/sanitizer"
require "sanitization/helpers"
require "sanitization/active_record_extension"
require "active_record" unless defined?(ActiveRecord)

module Sanitization
  class Error < StandardError; end
end

ActiveRecord::Base.class_eval do
  include Sanitization::ActiveRecordExtension
end
