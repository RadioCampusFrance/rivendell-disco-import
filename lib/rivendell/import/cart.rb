module Rivendell::Import
  class Cart

    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON

    def as_json(options = {})
      super options.merge(:root => false)
    end

    def attributes
      attributes = {}
      %w{number group clear_cuts title default_title scheduler_codes artist album import_options}.each do |attribute|
        value = send attribute
        attributes[attribute] = value if value.present?
      end
      if (cut_attributes = cut.attributes).present?
        attributes["cut"] = cut_attributes
      end
      attributes
    end

    def attributes=(attributes)
      attributes.each do |k,v|
        unless k == "cut"
          send "#{k}=", v
        else
          cut.attributes = v
        end
      end
    end

    delegate :blank?, :to => :attributes

    attr_accessor :number, :group, :title, :default_title, :scheduler_codes, :artist, :album
    attr_reader :task

    def initialize(task = nil)
      @task = task
    end

    def scheduler_codes
      @scheduler_codes ||= []
    end

    def xport
      task.xport
    end

    def create
      unless number
        raise "Can't create Cart, Group isn't defined" unless group.present?
        self.number = xport.add_cart(:group => group).number
      end
    end

    def update
      updaters.any? do |updater|
        updater.new(self).update
      end
    end

    def updaters
      [].tap do |updaters|
        updaters << ApiUpdater if scheduler_codes.empty?
        updaters << DbUpdater if Database.enabled?
      end
    end

    class Updater

      attr_accessor :cart

      def initialize(cart)
        @cart = cart
      end
      delegate :number, :title, :default_title, :scheduler_codes, :artist, :album, :to => :cart

      def empty_title?(title)
        [ nil, "", "[new cart]" ].include? title
      end

      def title_with_default
        @title_with_default ||=
          if title
            title
          else
            default_title if default_title && empty_title?(current_title)
          end
      end

      def update
        begin
          update!
        rescue => e
          Rivendell::Import.logger.debug "#{self.class.name} failed : #{e}"
          false
        end
      end

    end

    class ApiUpdater < Updater

      def update!
        unless attributes.empty?
          Rivendell::Import.logger.debug "Update Cart by API : #{attributes}"
          xport.edit_cart number, attributes
        else
          true
        end
      end

      delegate :xport, :to => :cart

      def current_title
        xport.list_cart(number).title
      end

      def attributes
        {}.tap do |attributes|
          attributes[:title] = title_with_default if title_with_default
          attributes[:artist] = artist if artist
          attributes[:album] = album if album
        end
      end

    end

    class DbUpdater < Updater

      def current_cart
        @current_cart ||= Rivendell::DB::Cart.get(number)
      end

      def current_title
        current_cart.title
      end

      def update!
        Database.init

        if title_with_default or artist or album or not scheduler_codes.empty?
          Rivendell::Import.logger.debug "Update Cart by DB"
          current_cart.title = title_with_default if title_with_default
          current_cart.scheduler_codes = scheduler_codes unless scheduler_codes.empty?
          current_cart.artist = artist if artist
          current_cart.album = album if album
          current_cart.save
        end
      end

    end

    def cut
      @cut ||= Cut.new(self)
    end

    attr_accessor :import_options
    def import_options
      @import_options ||= {}
    end

    def import(file)
      raise "File #{file.path} not found" unless file.exists?

      if clear_cuts?
        Rivendell::Import.logger.debug "Clear cuts of Cart #{number}"
        xport.clear_cuts number
      end
      cut.create

      Rivendell::Import.logger.debug "Import #{file.path} in Cut #{cut.number}"
      xport.import number, cut.number, file.path, import_options.symbolize_keys
      cut.update
    end

    def find_by_title(string, options = {})
      Rivendell::Import.logger.debug "Looking for a Cart '#{string}'"
      if remote_cart = cart_finder.find_by_title(string, options)
        Rivendell::Import.logger.debug "Found Cart #{remote_cart.number}"
        self.number = remote_cart.number
        self.import_options[:use_metadata] = false
      end
    end

    attr_accessor :clear_cuts
    alias_method :clear_cuts?, :clear_cuts

    def clear_cuts!
      self.clear_cuts = true
    end

    def cart_finder
      @cart_finder ||=
        unless Database.enabled?
          Rivendell::Import::CartFinder::ByApi.new xport
        else
          Rivendell::Import::CartFinder::ByDb.new
        end
    end

  end
end
