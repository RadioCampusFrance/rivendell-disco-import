$: << File.dirname(__FILE__) + "/../../lib"

require "rivendell/import"

require "logger"
Rivendell::Import.logger = ActiveRecord::Base.logger = Logger.new("log/cucumber.log")

Rivendell::Import.establish_connection "db/test.sqlite3"

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

Before do
  DatabaseCleaner.start
end

After do |scenario|
  DatabaseCleaner.clean
end
