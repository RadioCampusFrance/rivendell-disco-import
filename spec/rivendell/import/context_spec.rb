require 'spec_helper'

describe Rivendell::Import::Context do

  let(:file) { Rivendell::Import::File.new "dummy.wav" }
  let(:task) { Rivendell::Import::Task.new :file => file }

  subject { Rivendell::Import::Context.new task }

  describe "#notify" do

    it "should add the specified notifier to the task" do
      subject.notify 'recipient@domain', :by => :email
      subject.task.notifiers.first.to.should == 'recipient@domain'
    end

  end

  describe "#log" do

    let(:message) { "dummy" }

    it "should log the given message with info level" do
      subject.logger.should_receive(:info).with(message)
      subject.log message
    end

  end

end
