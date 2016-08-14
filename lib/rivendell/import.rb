require "rivendell/import/version"

require "null_logger"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/hash/except"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"
require "active_support/hash_with_indifferent_access"
require 'taglib'

require "rivendell/import/config"

module Rivendell
  module Import

    @@config = Config.new
    def self.config(&block)
      yield @@config if block_given?
      @@config
    end

    @@logger = NullLogger.instance
    mattr_accessor :logger

    def self.establish_connection(file_or_uri = "db.sqlite3")
      database_spec =
        if URI.parse(file_or_uri).scheme.in? [nil, "file"]
          { :adapter => "sqlite3", :database => file_or_uri }
        else
          file_or_uri
        end

      ActiveRecord::Base.establish_connection database_spec
      ActiveRecord::Migrator.migrate(::File.expand_path("../../../db/migrate/", __FILE__), nil)
    end

  end
end

require 'listen'

require 'active_record'
ActiveRecord::Base.include_root_in_json = false

require "rivendell/api"

require "rivendell/import/config"
require "rivendell/import/config_loader"
require "rivendell/import/worker"
require "rivendell/import/task"
require "rivendell/import/tasks"
require "rivendell/import/base"
require "rivendell/import/database"
require "rivendell/import/cart_finder"
require "rivendell/import/cart"
require "rivendell/import/context"
require "rivendell/import/cut"
require "rivendell/import/file"
require "rivendell/import/notification"
require "rivendell/import/notifier/base"
require "rivendell/import/notifier/mail"

# TODO Rivendell::Import::CartFinder::ByDb should be optional
require 'rivendell/db'
require 'rivendell/import/cart_finder_by_db'
