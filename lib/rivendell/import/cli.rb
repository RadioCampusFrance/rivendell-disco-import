require 'trollop'
require 'logger'
require 'syslog/logger'

module Rivendell::Import
  class CLI

    attr_reader :arguments
    attr_accessor :options_count

    def initialize(arguments = [])
      @arguments = arguments
    end

    def config_file
      @config_file ||= options[:config]
    end

    def listen_mode?
      options[:listen]
    end

    def dry_run?
      options[:dry_run]
    end

    def debug?
      options[:debug]
    end

    def syslog?
      options[:syslog]
    end

    def daemonize?
      options[:daemon]
    end

    def pid_directory
      options[:pid_dir] or Dir.pwd
    end

    def database
      options[:database]
    end

    def parser
      @parser ||= Trollop::Parser.new do
        opt :config, "Configuration file", :type => String #, :required => true
        opt :listen, "Wait for files in given directory"
        opt :dry_run, "Just create tasks without executing them"
        opt :debug, "Enable debug messages (in stderr)"
        opt :syslog, "Log messages to syslog"
        opt :database, "The database file used to store tasks", :type => String
        opt :daemon, "Run in background"
        opt :pid_dir, "Directory to store pid", :type => String
      end
    end

    def options
      @options ||= Trollop::with_standard_exception_handling(parser) do
        raise Trollop::HelpNeeded if ARGV.empty? # show help screen
        parser.parse arguments
      end
    end
    alias_method :parse, :options

    def parsed_parser
      parse
      parser
    end

    def import
      @import ||= Rivendell::Import::Base.new
    end

    def paths
      parsed_parser.leftovers
    end

    def setup_logger
      new_logger =
        if syslog?
          Syslog::Logger.new('rivendell-import').tap do |syslog|
            syslog.level = debug? ? Logger::DEBUG : Logger::INFO
          end
        elsif debug?
          Logger.new($stderr)
        end

      Rivendell::Import.logger = new_logger if new_logger
    end

    def start_webserver
      require 'rivendell/import/application'

      Rivendell::Import.logger.debug "Start webserver"

      Thread.new do
        Rivendell::Import::Application.set :config_loader, config_loader
        Rivendell::Import::Application.run!

        # FIXME we don't see difference between normal quit and start error (EADDRINUSE, ...)
        Rivendell::Import.logger.debug "Webserver is stopped"
        exit 0
      end
    end

    def config_loader
      @config_loader = ConfigLoader.new(config_file, listen_mode?)
    end

    def daemonize
      if daemonize?
        require 'daemons'
        Daemons.daemonize :app_name => "rivendell-import", :dir => pid_directory, :dir_mode => :normal
      end
    end

    def run
      setup_logger

      if database
        Rivendell::Import.establish_connection database
      else
        Rivendell::Import.establish_connection
      end

      config_loader.load

      daemonize

      config_loader.listen_file
      sleep 1

      if listen_mode?
        start_webserver
        sleep 1

        listen_options = {}
        listen_options[:dry_run] = true if dry_run?

        import.listen paths.first, listen_options
      else
        import.process paths
        import.tasks.run unless dry_run?
      end
    end
  end
end
