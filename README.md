# Rivendell::Import - Disco edition

Import music tracks like [Rivendell::Import](http://wiki.tryphon.eu/rivendell-import/start), but fetches their metadata in Disco.

The --disco option will supersede --listen, although both features could coexist.
Configure Disco URL and paths in the configuration file, see examples/config.rb .

## Run examples

    bundle exec ./bin/rivendell-import --config examples/config.rb --listen examples --debug

During development, run with `RUBYOPT="-I lib/" bin/rivendell-import`

## Initialize a dedicated MySQL database

    $ mysqladmin create import
    $ mysql mysql
    mysql> GRANT ALL PRIVILEGES ON import.* TO 'import'@'localhost' IDENTIFIED BY 'import';
    $ mysqladmin flush-privileges

Then use :

    rivendell-import [...] --database 'mysql://import:import@localhost/import' [...]
