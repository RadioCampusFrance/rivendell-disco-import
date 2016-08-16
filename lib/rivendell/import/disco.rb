module Rivendell::Import
  class Disco

    @@url = nil
    cattr_accessor :url

    @@dropbox_path = nil
    cattr_accessor :dropbox_path

    @@archive_path = nil
    cattr_accessor :archive_path

  end
end
