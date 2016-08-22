module Rivendell::Import
  class Disco
    include Singleton

    @@url = nil
    cattr_accessor :url

    @@dropbox_path = nil
    cattr_accessor :dropbox_path

    @@archive_path = nil
    cattr_accessor :archive_path

    @@default_to_prepare = nil
    cattr_accessor :default_to_prepare

    def to_prepare
      false or default_to_prepare
    end

    def initialize
      if @@url and @@dropbox_path
        @tasks = Tasks.new
      end
    end

    
  end
end
