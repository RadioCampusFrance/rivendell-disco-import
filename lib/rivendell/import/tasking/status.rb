module Rivendell::Import::Tasking
  module Status

    def define_default_status
      self.status ||= "pending"
    end

    def self.included(base)
      base.class_eval do
        after_initialize :define_default_status
      end
      base.extend ClassMethods
    end

    def raw_status
      read_attribute(:status)
    end

    def status
      ActiveSupport::StringInquirer.new(raw_status) if raw_status
    end

    def change_status!(status)
      logger.debug "Change status to #{status}"
      if persisted?
        update_attribute :status, status.to_s
      else
        self.status = status.to_s
      end
      # notify! if ran?
      invoke_status_changed_callbacks

      self
    end

    def invoke_status_changed_callbacks
      callbacks = self.class.status_changed_callbacks.values_at(:all, status.to_sym).flatten
      callbacks.each { |method| send method }
    end

    module ClassMethods

      def status_changed_callbacks
        @status_changed_callbacks ||= Hash.new { |h,k| h[k] = [] }
      end

      def after_status_changed(method, options = {})
        Array(options[:on] || :all).each do |status|
          status_changed_callbacks[status] << method
        end
      end

    end

  end
end
