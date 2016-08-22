# Rivendell::API::Xport.debug_output $stdout

Rivendell::Import.config do |config|
  config.rivendell.host = "host"
  config.rivendell.login_name = "user"
  config.rivendell.password = "pass"

  config.rivendell.db_url = 'mysql://rduser:letmein@localhost/Rivendell'

  # A running Disco install
  config.disco_url = 'http://domain.com/disco'

  # Where should we look at new albums to import ?
  config.dropbox_path = '/path/to/incoming/albums'

  # Optional - imported albums' folder will be moved there
  config.archive_path = '/path/to/archived/albums'

  # Common operations to be applied on any imported track
  # works as "to_prepare" in config.py in rivendell-import: you can also access file, cue, etc
  config.disco_common do |file|
    # task.cancel!

    cart.group = "MUSIC"

    cart.scheduler_codes ||= "MuPlayList"

  end
end
