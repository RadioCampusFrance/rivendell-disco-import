require 'spec_helper'

describe Rivendell::Import::Notifier::Mail do

  let(:mail_notifier) do
    Rivendell::Import::Notifier::Mail.new.tap do |notifier|
      notifier.from = "root@tryphon.eu"
      notifier.to = "root@tryphon.eu"
    end
  end

  subject { mail_notifier }

  let(:tasks) { [ Rivendell::Import::Task.new ] }

  describe "#template" do

    let(:file) { fixture_file("mail-body.erb") }
    
    it "should read file specified if exists" do
      subject.template(file).should == File.read(file)
    end

    it "should return given text if not file" do
      subject.template("dummy").should == "dummy"
    end

  end

  describe "#create_message" do
   
    it "should return a Rivendell::Import::Notifier::Mail::Message" do
      subject.create_message(tasks).should be_instance_of(Rivendell::Import::Notifier::Mail::Message)
    end

    describe "returned Message" do

      subject { mail_notifier.create_message(tasks) }
      
      its(:from) { should == mail_notifier.from }

      its(:to) { should == mail_notifier.to }

      its(:body) { should == mail_notifier.template(mail_notifier.body) }

      its(:subject) { should == mail_notifier.template(mail_notifier.subject) }
      
    end

  end

  describe "#notify!" do
    
    it "should deliver mail" do
      subject.subject = subject.body = "Dummy"
      subject.notify! tasks
      Mail::TestMailer.deliveries.last.subject.should == subject.subject
    end

  end

  describe "defaults" do
    
    subject { Rivendell::Import::Notifier::Mail.new } 

    its(:body) { should == File.expand_path("../../../../../lib/rivendell/import/notifier/mail-body.erb", __FILE__) }

    its(:subject) { should == File.expand_path("../../../../../lib/rivendell/import/notifier/mail-subject.erb", __FILE__) }

    it "should use defined default from" do
      Rivendell::Import::Notifier::Mail.from = "test@dummy"
      subject.from.should == Rivendell::Import::Notifier::Mail.from
    end

    after(:each) do
      Rivendell::Import::Notifier::Mail.from = nil
    end

  end

  describe "reloaded" do

    let(:original) { mail_notifier.save! ; mail_notifier }

    subject { Rivendell::Import::Notifier::Mail.find(original) }

    its(:from) { should == original.from }
    its(:to) { should == original.to }
    its(:subject) { should == original.subject }
    its(:body) { should == original.body }

  end

end

describe Rivendell::Import::Notifier::Mail::Message do

  let(:tasks) { [ mock ] }

  subject { Rivendell::Import::Notifier::Mail::Message.new(tasks) } 

  describe "#render" do
    
    it "should render ERB template with Message context" do
      subject.render("size: <%= tasks.size %>").should == "size: 1"
    end

  end

end
