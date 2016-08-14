def fixture_directory
  File.expand_path "../../fixtures", __FILE__
end

def fixture_file(name)
  File.join fixture_directory, name
end
