desc "Run continuous integration tasks (spec, ...)"
task :ci => %w{spec cucumber}
