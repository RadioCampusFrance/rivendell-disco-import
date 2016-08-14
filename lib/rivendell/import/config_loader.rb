module Rivendell::Import
  class ConfigLoader

    attr_accessor :file, :auto_reload
    alias_method :auto_reload?, :auto_reload

    def initialize(file, auto_reload = false)
      self.file = file
      self.auto_reload = auto_reload
    end

    def load
      Kernel.load file
    end

    def current_config
      ::File.read file
    end

    def save(config)
      ::File.write absolute_path, config
    end

    def listen_file
      return unless auto_reload?

      callback = Proc.new do |modified, added, removed|
        Rivendell::Import.logger.debug "Configuration changed ? #{[modified, added, removed].inspect}"
        if modified.include? absolute_path
          Rivendell::Import.logger.info "Configuration changed, reload it"
          load
        end
      end

      Rivendell::Import.logger.info "Listen to config file changes (#{file})"
      Listen.to(directory).filter(/^#{basename}$/).change(&callback).start
    end

    def listen_file_with_inotify
      require 'rb-inotify'

      notifier = INotify::Notifier.new.watch(file, :modify) do
        Rivendell::Import.logger.info "Configuration changed, reload it"
        load
      end

      Thread.new do
        Rivendell::Import.logger.info "Listen to config modification (#{file})"
        notifier.run
      end
    end

    def absolute_path
      ::File.expand_path(file)
    end

    def basename
      ::File.basename(file)
    end

    def directory
      ::File.dirname(file)
    end

  end
end
