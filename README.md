# Rivendell::Import

Next-Generation import interface for Rivendell

## Run examples

    bundle exec ./bin/rivendell-import --config examples/config.rb --listen examples --debug

## Initialize a dedicated MySQL database

    $ mysqladmin create import
    $ mysql mysql
    mysql> GRANT ALL PRIVILEGES ON import.* TO 'import'@'localhost' IDENTIFIED BY 'import';
    $ mysqladmin flush-privileges

Then use :

    rivendell-import [...] --database 'mysql://import:import@localhost/import' [...]
