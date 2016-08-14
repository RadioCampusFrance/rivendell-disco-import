require 'mail'
require 'erb'

module Rivendell::Import::Notifier
  class Mail < Rivendell::Import::Notifier::Base

    @@from = nil
    cattr_accessor :from

    attr_accessor :from, :to, :subject, :body

    def subject
      @subject ||= File.expand_path("../mail-subject.erb", __FILE__)
    end

    def body
      @body ||= File.expand_path("../mail-body.erb", __FILE__)
    end

    def from
      @from ||= self.class.from
    end

    def notify!(tasks)
      create_message(tasks).deliver!
    end

    def create_message(tasks)
      Message.new(tasks).tap do |mail|
        mail.from = from
        mail.to = to
        mail.subject = template(subject)
        mail.body = template(body)
      end
    end

    class Message

      attr_reader :tasks
      attr_accessor :from, :to, :subject, :body
      
      def initialize(tasks)
        @tasks = tasks
      end

      def completed
        tasks.select { |task| task.status.completed? }
      end

      def failed
        tasks.select { |task| task.status.failed? }
      end

      def failed?
        failed.present?
      end

      delegate :many?, :to => :tasks

      def mail
        ::Mail.new.tap do |mail|
          mail.from = from
          mail.to = to
          mail.subject = strip(render(subject))
          mail.body = render(body)
        end
      end

      def deliver!
        mail.deliver!
      end

      def render(template)
        ERB.new(template, nil, '%<>-').result(binding)
      end

      def strip(text)
        text.strip.gsub(/\n[ ]*/m,"")
      end

    end

    # def valid?
    #   [from, to, subject, body].all?(&:present?)
    # end

    def parameters
      %w{from to subject body}.inject({}) do |map, attribute|
        value = send attribute
        map[attribute] = value if value
        map
      end
    end

    def template(definition)
      if File.exists?(definition)
        File.read definition
      else
        definition
      end
    end

  end
end
