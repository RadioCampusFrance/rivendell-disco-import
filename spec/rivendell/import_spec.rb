require 'spec_helper'

describe Rivendell::Import do

  describe ".config" do

    context "without argument" do

      it "should return Rivendell::Import::Config instance" do
        Rivendell::Import.config.should be_instance_of(Rivendell::Import::Config)
      end

    end

    context "with a block" do

      it "should yield block with Config instance" do
        config_instance = Rivendell::Import.config
        Rivendell::Import.should_receive(:config).and_yield(config_instance)
        Rivendell::Import.config { |config| }
      end

      it "should return Config instance" do
        Rivendell::Import.config { |config| }.should == Rivendell::Import.config
      end

    end

  end

  describe ".establish_connection" do

    before do
      ActiveRecord::Base.stub :establish_connection
      ActiveRecord::Migrator.stub :migrate
    end

    context "when a file is given" do

      let(:file) { '/srv/rivendell/tmp/db.sqlite3' }

      it "should initialize a sqlite database" do
        ActiveRecord::Base.should_receive(:establish_connection).with({ :adapter => "sqlite3", :database => file })
        Rivendell::Import.establish_connection file
      end

    end

    context "when an url is given" do

      let(:url) { 'mysql://import:import@localhost/import' }

      it "should initialize database with given url" do
        ActiveRecord::Base.should_receive(:establish_connection).with(url)
        Rivendell::Import.establish_connection url
      end

    end

    it "should migrate database" do
      ActiveRecord::Migrator.should_receive(:migrate).with(File.expand_path("../../../db/migrate/", __FILE__), nil)
      Rivendell::Import.establish_connection
    end

  end

end
