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
            raise ArgumentError, "Unknown sanitizer: :#{sanitizer_name}"
          end
        end

        class_eval <<-RUBY
          include Sanitization::ActiveRecordExtension::InstanceMethods
          define_model_callbacks :sanitization, only: [:before, :after]
          before_validation :sanitize!
        RUBY
      end

      alias sanitize sanitizes

      def sanitizes_with(sanitizer)
        # Skip initialization if table is not yet created. For example, during migrations.
        begin
          return unless ActiveRecord::Base.connection.data_source_exists?(self.table_name)
        rescue ActiveRecord::NoDatabaseError
          return
        end

        unless sanitizer.is_a?(Class) && sanitizer.instance_methods(false).include?(:sanitize)
          raise ArgumentError, "Unknown sanitizer: '#{sanitizer}'"
        end

        self.sanitization__store ||= {}
        self.sanitization__store[:__model_sanitizer] = sanitizer

        class_eval <<-RUBY
          include Sanitization::ActiveRecordExtension::InstanceMethods
          define_model_callbacks :sanitization, only: [:before, :after]
          before_validation :sanitize!
        RUBY
      end

      def sanitizer_exists?(class_name)
        klass = Module.const_get(class_name)
        return false if !klass.is_a?(Class)
        return klass.instance_methods(false).include?(:sanitize_each)
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
            if attribute != :__model_sanitizer
              sanitized_value = sanitization__sanitize_attribute(attribute, config)
              self.public_send("#{attribute}=".to_sym, sanitized_value)
            end
          end
          if self.class.sanitization__store[:__model_sanitizer].present?
            self.class.sanitization__store[:__model_sanitizer].new.sanitize(self)
          end
        end
      end

      def sanitization__sanitize_attribute(attribute, config)
        original_value = self.public_send(attribute.to_sym)
        sanitized_value = config.reduce(original_value) do |value, (sanitizer, options)|
          if Sanitization::HELPERS.include?(sanitizer)
            sanitization__apply_sanitizer(value, sanitizer, options)
          elsif options.is_a?(Class) && options.instance_methods(false).include?(:sanitize_each)
            user_defined_sanitizer_class = options
            user_defined_sanitizer_class.new.sanitize_each(self, attribute, value)
          end
        end
      end

      # @return the modified attribute value
      def sanitization__apply_sanitizer(value, sanitizer, options)
        case sanitizer
        when :case
          sanitize_case(value, options)
        when :gsub
          value&.gsub(options[:pattern], options[:replacement])
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
          value&.remove(options)
        when :round
          value&.round(options)
        when :squish
          options == true ? value&.squish : value
        when :strip
          options == true ? value&.strip : value
        when :truncate
          value.to_s.truncate(options, omission: '')
        end
      end

      # Converts the provided value to the given case
      #
      # @param value [String] the value to convert
      # @param kase [:upcase, :downcase, :camelcase, :snakecase, :titlecase,
      #   :pascalcase] the case to convert to
      # @return [String]
      def sanitize_case(value, kase)
        return value if value.nil?

        if kase == :camelcase
          value.camelcase(:lower)
        elsif kase == :pascalcase
          value.camelcase(:upper)
        else
          value.send(kase)
        end
      end
    end # module InstanceMethods
  end # module ActiveRecordExt
end # module Sanitization
