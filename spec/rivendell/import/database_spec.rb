require 'spec_helper'

describe Rivendell::Import::Database do

  it "should be enabled when url is defined" do
    Rivendell::Import::Database.url = "dummy"
    Rivendell::Import::Database.should be_enabled
  end

  after do
    Rivendell::Import::Database.url = nil
  end

end
