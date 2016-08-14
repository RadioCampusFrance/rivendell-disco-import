require 'spec_helper'

describe Rivendell::Import::Config do

  let(:config) { Rivendell::Import::Config.new }

  describe "#to_prepare" do

    let(:user_block) { Proc.new {} }

    it "should define Base.default_to_prepare with given block" do
      subject.to_prepare(&user_block)
      Rivendell::Import::Base.default_to_prepare.should == user_block
    end

  end

  describe "#rivendell" do

    subject { config.rivendell }

    def self.it_should_define_task_default_xport_option(attribute)
      describe "#{attribute}=" do
        attribute = attribute.to_sym
        it "should define Task.default_xport_options[:#{attribute}]" do
          subject.send "#{attribute}=", "dummy"
          Rivendell::Import::Task.default_xport_options[attribute].should == "dummy"
        end
      end
    end

    it_should_define_task_default_xport_option :host
    it_should_define_task_default_xport_option :login_name
    it_should_define_task_default_xport_option :password

    it "should define Database.url" do
      subject.db_url = "dummy"
      Rivendell::Import::Database.url.should == "dummy"
    end

    after do
      Rivendell::Import::Database.url = nil
    end


  end

end
