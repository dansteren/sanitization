require "sanitization/version"
require "sanitization/helpers"
require "sanitization/active_record_extension"
require "active_record" unless defined?(ActiveRecord)

module Sanitization
  class Error < StandardError; end
end

ActiveRecord::Base.class_eval do
  include Sanitization::ActiveRecordExtension
  define_model_callbacks :sanitization, only: [:before, :after]
end
