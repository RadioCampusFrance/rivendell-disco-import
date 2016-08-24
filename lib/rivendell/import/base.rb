require 'thread'

module Rivendell::Import
  class Base

    attr_reader :tasks, :workers

    def initialize
      @tasks = Tasks.new
      @workers = []
    end

    @@default_to_prepare = nil
    cattr_accessor :default_to_prepare

    attr_accessor :to_prepare
    def to_prepare
      @to_prepare or default_to_prepare
    end

    def listen(directory, options = {})
      workers << Worker.new(self).start unless options[:dry_run]

      Rivendell::Import.logger.info "Listen files in #{directory}"
      callback = Proc.new do |modified, added, removed|
        # Rivendell::Import.logger.debug [modified, added, removed].inspect
        added.each do |file|
          begin
            Rivendell::Import.logger.debug "Detected file '#{file}'"
            file(file, directory)
          rescue Exception => e
            Rivendell::Import.logger.error "Task creation failed : #{e}"
            Rivendell::Import.logger.debug e.backtrace.join("\n")
          end
        end
      end

      Listen.to(directory, latency: 1, wait_for_delay: 5).change(&callback).start!
    end

    def process(*paths)
      paths.flatten.each do |path|
        method = ::File.directory?(path) ? :directory : :file
        send method, path
      end
    end

    attr_accessor :file_patterns
    def file_patterns
      @file_patterns ||= ["**/*", "*"]
    end

    def ignore?(path)
      not file_patterns.any? do |file_pattern|
        ::File.fnmatch file_pattern, path, ::File::FNM_PATHNAME | ::File::FNM_CASEFOLD
      end
    end

    def file(path, base_directory = nil)
      return if ignore? path

      path = ::File.expand_path(path, base_directory)
      file = Rivendell::Import::File.new path, :base_directory => base_directory
      create_task file
    end

    def directory(directory)
      Dir[::File.join(directory, "**/*")].each do |file|
        file(file, directory) if ::File.file?(file)
      end
    end

    def create_task(file)
      Rivendell::Import.logger.debug "Create task for #{file}"
      tasks.create(file) do |task|
        prepare_task task
      end
    end

    def prepare_task(task)
      task.prepare(&to_prepare) if to_prepare
    end

  end
end
