module Rivendell::Import
  class Notifiers

    attr_reader :import, :notifiers

    def initialize
      @import = import
    end

    def push(notifier)
      notifiers << notifier
    end

    def notify!
      notified_tasks = waiting_tasks
      @waiting_tasks = []

      notifiers.each do |notifier|
        notifier.notify notified_tasks
      end
    end

  end
end
