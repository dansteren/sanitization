module Sanitization
  module ActiveRecordExtension
    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :sanitization__store

      private

      def sanitizes(attribute, kwargs = {})
        # Skip initialization if table is not yet created. For example, during migrations.
        begin
          return unless ActiveRecord::Base.connection.data_source_exists?(self.table_name)
        rescue ActiveRecord::NoDatabaseError
          return
        end

        raise ActiveModel::MissingAttributeError, "missing attribute: #{attribute}" if !has_attribute?(attribute)
        raise ArgumentError, "You need to supply at least one sanitization" if kwargs.empty?

        self.sanitization__store ||= {}
        self.sanitization__store[attribute] ||= {}

        kwargs.each_pair do |sanitizer_name, options|
          if Sanitization::HELPERS.include?(sanitizer_name)
            self.sanitization__store[attribute][sanitizer_name] = options
          elsif sanitizer_exists?("#{sanitizer_name.to_s.camelcase(:upper)}Sanitizer")
            self.sanitization__store[attribute][sanitizer_name] = "#{sanitizer_name.to_s.camelcase(:upper)}Sanitizer".constantize
          else
            raise ArgumentError, "Unknown sanitizer: '#{sanitizer_name}'"
          end
        end

        class_eval <<-RUBY
          include Sanitization::ActiveRecordExtension::InstanceMethods
          define_model_callbacks :sanitization, only: [:before, :after]
          before_validation :sanitize!
        RUBY
      end

      alias sanitize sanitizes

      def sanitizer_exists?(class_name)
        klass = Module.const_get(class_name)
        return false if !klass.is_a?(Class)
        return (klass < Sanitization::EachSanitizer) ? true : false
      rescue NameError
        return false
      end
    end # module ClassMethods

    module InstanceMethods
      private

      def sanitize!
        return unless self.class.sanitization__store
        run_callbacks :sanitization do
          self.class.sanitization__store.each_pair do |attribute, config|
            self.public_send("#{attribute}=".to_sym, sanitization__sanitize_attribute(attribute, config))
          end
        end
      end

      def sanitization__sanitize_attribute(attribute, config)
        original_value = self.public_send(attribute.to_sym)
        sanitized_value = config.reduce(original_value) do |value, (sanitizer, options)|
          sanitization__apply_sanitizer(value, sanitizer, options)
        end
      end

      # @return the modified attribute value
      def sanitization__apply_sanitizer(value, sanitizer, options)
        case sanitizer
        when :case
          sanitize_case(value, options)
        when :gsub
          value.gsub(options[:pattern], options[:replacement])
        when :nullify
          if options == true
            if value == false
              value
            elsif value.blank?
              nil
            else
              value
            end
          else
            value
          end
        when :remove
          value.remove(options)
        when :round
          value.round(options)
        when :squish
          options == true ? value.squish : value
        when :strip
          options == true ? value.strip : value
        when :truncate
          value.to_s.truncate(options, omission: '')
        else
          raise NotImplementedError, "TODO: implement handlers for EachSanitizers"
        end
      end
    end # module InstanceMethods
  end # module ActiveRecordExt
end # module Sanitization
