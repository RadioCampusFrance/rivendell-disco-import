module Rivendell::Import
  class Context

    attr_reader :task

    def initialize(task)
      @task = task
    end

    delegate :file, :cart, :logger, :to => :task

    def with(expression)
      yield if file.match expression
    end

    def notify(target, options = {})
      Rivendell::Import::Notifier::Base.notify(target, options).tap do |notifier|
        logger.debug "Will notify with #{notifier.inspect}"
        task.notifiers << notifier
      end
    end

    def log(message)
      logger.info message if message
    end

    def run(&block)
      instance_exec file, &block if block_given?
    end

  end
end
