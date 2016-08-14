require 'mail'
require 'erb'

module Rivendell::Import::Notifier
  class Base < ActiveRecord::Base

    # self.abstract_class = true
    self.table_name = "notifiers"

    def parameters
      {}
    end

    has_many :notifications, :foreign_key => "notifier_id" do
      def to_sent
        pending.joins(:task).where("tasks.status" => %w{completed failed})
      end
      def waiting_for_more_than(delay)
        joins(:task).where("tasks.updated_at < ?", Time.now - delay)
      end
    end

    has_many :tasks, :through => :notifications

    def delay
      tasks.pending.empty? ? 0 : 60
    end

    def notify
      to_sent_notifications = notifications.to_sent.includes(:task)

      if delay > 0
        to_sent_notifications = to_sent_notifications.waiting_for_more_than(delay)
      end

      if to_sent_notifications.present?
        logger.debug "Notify #{to_sent_notifications.size} tasks with #{self.inspect}"
        notify! to_sent_notifications.map(&:task)
        to_sent_notifications.update_all(:sent_at => Time.now)
      end
    end

    def logger
      Rivendell::Import.logger
    end

    def parameters=(parameters)
      parameters.each { |k,v| send "#{k}=", v }
    end
    
    def raw_parameters
      read_attribute :parameters
    end

    def read_parameters
      self.parameters = ActiveSupport::JSON.decode(raw_parameters) if raw_parameters.present?
    end

    after_initialize :read_parameters

    def parameters_hash
      parameters_as_string = parameters.sort_by { |p| p.first.to_s }.flatten.join('-')
      Digest::SHA256.hexdigest parameters_as_string
    end

    def write_parameters
      if parameters.present?
        write_attribute :parameters, parameters.to_json
        write_attribute :key, parameters_hash
      else
        write_attribute :parameters, nil
        write_attribute :key, nil
      end
    end

    before_save :write_parameters

    def self.notify(target, options = {})
      new_notifier = case options.delete(:by)
                     when :email
                       Mail.new options.merge(:to => target)
                     end

      key = new_notifier.parameters_hash
      if existing_notifier = where(:type => new_notifier.type, :key => key).first
        existing_notifier
      else
        new_notifier.save!
        new_notifier
      end
    end
    
  end
end
