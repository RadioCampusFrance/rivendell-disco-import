require 'spec_helper'

describe Rivendell::Import::Cut do

  let(:task) { mock }
  let(:cart) { Rivendell::Import::Cart.new task }
  subject { Rivendell::Import::Cut.new cart }

  describe "initialization" do

    it "should use the given cart" do
      Rivendell::Import::Cut.new(cart).cart.should == cart
    end

  end

  describe "#to_json" do

    let(:json_clone) do
      Rivendell::Import::Cut.new(cart).tap do |clone|
        clone.from_json subject.to_json, false
      end
    end

    it "should support datetime (Time range)" do
      subject.datetime =  Time.parse("2014-03-20 00:00")..Time.parse("2014-03-21 23:59:59")
      json_clone.datetime.should == subject.datetime
    end

    it "should support datepart (String range)" do
      subject.daypart = "08:00:00".."12:00:00"
      json_clone.daypart.should == subject.daypart
    end

  end

  describe "#create" do

    before(:each) do
      subject.stub :xport => mock
    end

    it "should use Xport#add_cut with Cart number" do
      subject.cart.number = 123
      subject.xport.should_receive(:add_cut).with(123).and_return(mock(:number => "000123_001"))
      subject.create
    end

    it "should use the number returned by Xport#add_cut" do
      subject.cart.number = 123
      subject.xport.should_receive(:add_cut).with(123).and_return(mock(:number => "000123_001"))
      subject.create
      subject.number.should == "000123_001"
    end

  end

  describe "#update" do

    before do
      subject.number = 1
      subject.cart.number = 1
    end

    context "when DB attributes are defined" do

      let(:db_cut) do
        Struct.new(:start_datetime, :end_datetime, :start_daypart, :end_daypart, :days) do
          def save; true; end
        end.new
      end

      before do
        subject.stub :db_attributes? => true
        Rivendell::DB::Cut.stub :get => db_cut
        Rivendell::Import::Database.stub :init
      end

      it "should retrieve the DB Cut with number" do
        Rivendell::DB::Cut.should_receive(:get).with(subject.name).and_return(db_cut)
        subject.update
      end

      it "should save the DB Cut" do
        db_cut.should_receive(:save)
        subject.update
      end

      it "should define DB Cut start_datetime and end_datetime when datetime range is defined" do
        begin_of_december = Time.parse("1 December 2013")
        end_of_december = Time.parse("31 December 2013")
        subject.datetime = begin_of_december..end_of_december

        subject.update

        db_cut.start_datetime.should == begin_of_december
        db_cut.end_datetime.should == end_of_december
      end

      it "should define DB Cut start_daypart and end_daypart when daypart range is defined" do
        subject.daypart = "12:00:00".."14:00:00"

        subject.update

        db_cut.start_daypart.should == "12:00:00"
        db_cut.end_daypart.should == "14:00:00"
      end

      it "should define DB Cut days when defined" do
        subject.days = %{mon}
        subject.update
        db_cut.days.should == subject.days
      end

    end

    context "when API attributes are defined" do

      before do
        subject.description = "dummy"
        subject.stub :xport => mock
      end

      it "should invoke xport to edit cut" do
        subject.xport.should_receive(:edit_cut).with(subject.cart.number, subject.number, "description" => subject.description)
        subject.update
      end

    end

  end

  describe "#name" do

    it "should return 001015_001 for cart number 1015 and number 1" do
      subject.number = 1
      subject.cart.number = 1015
      subject.name.should == "001015_001"
    end

  end

end
