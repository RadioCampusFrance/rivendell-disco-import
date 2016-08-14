require 'spec_helper'

describe Rivendell::Import::Base do

  describe "#prepare_task" do

    let(:task) { mock }

    it "should prepare task with to_prepare block" do
      subject.to_prepare = Proc.new {}
      task.should_receive :prepare
      subject.prepare_task task
    end

  end

  describe "#to_prepare" do

    let(:block) { mock }

    it "should use default_to_prepare if not defined" do
      subject.stub :default_to_prepare => block
      subject.to_prepare.should == block
    end

  end

  describe "#create_task" do

    let(:file) { Rivendell::Import::File.new "dummy.wav" }

    it "should create a task with given file" do
      Rivendell::Import::Task.should_receive(:create).with({:file => file}, {})
      subject.create_task file
    end

    it "should prepare task" do
      subject.should_receive(:prepare_task)
      subject.create_task file
    end

  end

  describe "#file" do

    let(:file) { Rivendell::Import::File.new("dummy.wav") }

    it "should create a File with given path and base_directory" do
      subject.file("path", "base_directory").file_path.should == File.expand_path("path", "base_directory")
    end

    it "should create a File with given path and base_directory" do
      Rivendell::Import::File.stub :new => file
      subject.should_receive(:create_task).with(file)
      subject.file "path", "base_directory"
    end

  end

  describe "#directory" do

    it "should look for files in given directory" do
      Dir.mktmpdir do |directory|
        FileUtils.mkdir "#{directory}/subdirectory"

        file = "#{directory}/subdirectory/dummy.wav"
        FileUtils.touch file

        subject.should_receive(:file).with(file, directory)
        subject.directory directory
      end
    end

  end

  describe "#process" do

    it "should use file method when path isn't a directory" do
      File.stub :directory? => false
      subject.should_receive(:file).with("dummy")
      subject.process("dummy")
    end

    it "should use directory method when path is a directory" do
      File.stub :directory? => true
      subject.should_receive(:directory).with("dummy")
      subject.process("dummy")
    end

  end

  describe "#listen" do

    before(:each) do
      Listen.stub :to => mock(:change => mock(:start! => true))
    end

    let(:directory) { "directory" }
    let(:worker) { mock }

    before(:each) do
      worker.stub :start => worker
      Rivendell::Import::Worker.stub :new => worker
    end

    it "should create a Worker" do
      Rivendell::Import::Worker.should_receive(:new).with(subject).and_return(worker)
      subject.listen directory
      subject.workers.should == [ worker ]
    end

    it "should start Worker" do
      worker.should_receive(:start).and_return(worker)
      subject.listen directory
    end

    it "should not create Worker with dry_run option" do
      subject.listen directory, :dry_run => true
      subject.workers.should be_empty
    end

    it "should invoke Listen.to with given directory" do
      Listen.should_receive(:to).with(directory, anything)
      subject.listen directory
    end

  end

  describe "#ignore?" do

    context "when default file patterns" do

      it "should ignore hidden file" do
        subject.ignore?("path/to/.nfs00000000074200420000000c").should be_true
        subject.ignore?(".nfs00000000074200420000000c").should be_true
      end

      it "should accept files in directories" do
        subject.ignore?("path/to/normal_file.mp3").should be_false
      end

      it "should accept files in root directory" do
        subject.ignore?("file").should be_false
      end

    end

  end

end
