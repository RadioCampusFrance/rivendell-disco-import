module Rivendell::Import
  class Tasks

    def pop
      ready_tasks.first
    end

    def run
      ready_tasks.each(&:run)
    end

    def ready_tasks
      Task.ready
    end

    def create(file, &block)
      retry_count = 3
      begin
        Rivendell::Import::Task.create({:file => file}, {}, &block).tap do |task|
          Rivendell::Import.logger.debug "Created task #{task.inspect}"
        end
      rescue Exception => e
        Rivendell::Import.logger.error "Can't create Task: #{e}"
        retry_count -= 1
        if retry_count > 0
          Rivendell::Import.logger.error "Retry in 5s"
          sleep 5
          retry
        end
      end
    end

  end
end
