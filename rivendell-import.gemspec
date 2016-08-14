# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rivendell/import/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alban Peignier"]
  gem.email         = ["alban@tryphon.eu"]
  gem.description   = %q{Import sound in our Rivendell system}
  gem.summary       = %q{Import engine for Rivendell}
  gem.homepage      = "http://wiki.tryphon.eu/rivendell-import/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rivendell-import"
  gem.require_paths = ["lib"]
  gem.version       = Rivendell::Import::VERSION

  # 2.0 requires ruby 1.9.3
  gem.add_runtime_dependency 'listen', '~> 1.3.1'
  gem.add_runtime_dependency 'httmultiparty'
  # 0.12.0 requires ruby 1.9.3
  gem.add_runtime_dependency 'httparty', '0.11.0'
  gem.add_runtime_dependency 'mime-types', '~> 2.4.3'
  gem.add_runtime_dependency 'rivendell-api', '~> 0.9'
  gem.add_runtime_dependency 'trollop'
  gem.add_runtime_dependency 'activerecord', '~> 3.2.8'
  gem.add_runtime_dependency 'activesupport', '~> 3.2.8'
  gem.add_runtime_dependency 'mail'
  gem.add_runtime_dependency 'sqlite3'
  gem.add_runtime_dependency 'SyslogLogger', '~> 2.0'
  gem.add_runtime_dependency 'taglib-ruby'

  gem.add_runtime_dependency 'sinatra'
  gem.add_runtime_dependency 'will_paginate', '~> 3.0.0'

  gem.add_runtime_dependency 'daemons'

  gem.add_runtime_dependency 'rivendell-db', '~> 0.3'

  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "guard"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency "guard-cucumber"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rdoc"
  gem.add_development_dependency "cucumber"
  gem.add_development_dependency "database_cleaner"

  # gem.add_development_dependency "remarkable_activerecord"
end
