namespace :db do
  namespace :test do
    task :prepare => 'db:test:purge'

    task :purge do
      sh "rm -f db/test.sqlite3"
    end
  end
end

task :spec => 'db:test:prepare'
