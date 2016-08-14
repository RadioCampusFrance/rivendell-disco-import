require 'spec_helper'

describe Rivendell::Import::Tasks do

  let(:file) { Rivendell::Import::File.new "dummy.wav" }

  describe "#run" do

    it "should run each ready task" do
      task = subject.create(file)
      subject.stub :ready_tasks => [task]
      subject.run rescue nil
      task.reload.status.should_not be_pending
    end

  end

end
