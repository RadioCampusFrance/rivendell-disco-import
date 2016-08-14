require 'rivendell/import/tasking/file'
require 'rivendell/import/tasking/tags'
require 'rivendell/import/tasking/cart'
require 'rivendell/import/tasking/status'
require 'rivendell/import/tasking/destination'

module Rivendell::Import
  class Task < ActiveRecord::Base
    include Rivendell::Import::Tasking::File
    include Rivendell::Import::Tasking::Tags
    include Rivendell::Import::Tasking::Cart
    include Rivendell::Import::Tasking::Status
    include Rivendell::Import::Tasking::Destination

    def self.pending
      where :status => "pending"
    end

    def self.ready
      pending.by_priority.select(&:ready?)
    end

    def self.by_priority
      order(["priority desc", "created_at"])
    end

    RAN_STATUSES = %w{completed failed canceled}.freeze

    def self.ran
      where :status => RAN_STATUSES
    end

    def self.search(text)
      where [ "lower(file_name) like ?", "%#{text.downcase}%" ]
    end

    def ran?
      status.in? RAN_STATUSES
    end

    @@default_xport_options = {}
    cattr_accessor :default_xport_options

    def raw_xport_options
      read_attribute :xport_options
    end

    def xport_options
      @xport_options ||= (raw_xport_options ? JSON.parse(raw_xport_options).with_indifferent_access : default_xport_options.dup)
    end

    def write_xport_options
      write_attribute :xport_options, (xport_options.present? ? xport_options.to_json : nil)
    end
    before_save :write_xport_options

    def xport
      @xport ||= Rivendell::API::Xport.new(xport_options)
    end

    def prepare(&block)
      begin
        Context.new(self).run(&block)
      rescue => e
        logger.error "Task preparation failed : #{e}"
        change_status! :failed
      end
      self
    end

    def logger
      Rivendell::Import.logger
    end

    def to_s
      "Import '#{file}' in #{destination}"
    end

    has_many :notifications
    has_many :notifiers, :through => :notifications

    def notify!
      notifiers.each do |notifier|
        notifier.notify
      end
    end
    after_status_changed :notify!, :on => [:completed, :failed]

    def ready?
      status.pending? and file_ready?
    end

    def detailed_status
      if status.pending? and not ready?
        "waiting"
      else
        status
      end
    end

    def file_ready?
      file.ready?
    end

    def destroy_file!
      file.destroy! if delete_file?
    end

    def cancel!
      self.status = "canceled"
    end

    def run
      if status.canceled?
        logger.debug "Don't run canceled task : #{self.inspect}"
        return
      end

      logger.debug "Run #{self.inspect}"
      change_status! :running

      reset_destination!

      cart.create
      cart.import file
      cart.update

      destroy_file!
      change_status! :completed

      logger.info "Imported Cart #{cart.number}"
    rescue Exception => e
      logger.error "Task failed : #{e}"
      logger.debug e.backtrace.join("\n")
    ensure
      close_file

      unless ran?
        change_status! :failed
      end
      save!
    end

    after_create :purge!

    def purge!
      self.class.purge!
    end

    def self.purge!
      where("created_at < ?", 24.hours.ago).destroy_all
    end

  end
end
