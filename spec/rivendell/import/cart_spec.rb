require 'spec_helper'

describe Rivendell::Import::Cart do

  let(:task) { mock }
  subject { Rivendell::Import::Cart.new task }

  describe "initialization" do

    it "should use the given task" do
      Rivendell::Import::Cart.new(task).task.should == task
    end

  end

  describe "#xport" do

    before(:each) do
      task.stub :xport => mock
    end

    it "should be task xport" do
      subject.xport.should == subject.task.xport
    end

  end

  describe "#create" do

    before(:each) do
      subject.stub :xport => mock
    end

    it "should use Xport#add_cart with Cart group" do
      subject.group = "dummy"
      subject.xport.should_receive(:add_cart).with(:group => subject.group).and_return(mock(:number => 123))
      subject.create
    end

    it "should use the number returned by Xport#add_cart" do
      subject.xport.stub(:add_cart).and_return(mock(:number => 123))
      subject.group = "dummy"
      subject.create
      subject.number.should == 123
    end

    context "when number is already defined" do

      before(:each) do
        subject.number = 666
      end

      it "should not invoke Xport#add_cart" do
        subject.xport.stub(:add_cart).and_return(mock(:number => 123))
        subject.create
        subject.number.should == 666
      end

    end

    context "when group isn't defined" do

      it "should raise an error" do
        subject.group = nil
        lambda { subject.create }.should raise_error
      end

    end

  end

  describe "#cut" do

    it "should return a Cut associated to this Cart" do
      subject.cut.cart.should == subject
    end

  end

  describe "#import" do

    let(:file) { mock :path => "dummy", :exists? => true }

    before(:each) do
      subject.number = 123
      subject.stub :cut => mock.as_null_object, :xport => mock.as_null_object
    end

    it "should create Cut" do
      subject.cut.should_receive :create
      subject.import file
    end

    it "should import file via xport with Cart and Cut numbers" do
      subject.xport.should_receive(:import).with(subject.number, subject.cut.number, file.path, {})
      subject.import file
    end

    it "should use import options if specified" do
      subject.import_options[:dummy] = true
      subject.xport.should_receive(:import).with(subject.number, subject.cut.number, file.path, subject.import_options)
      subject.import file
    end

    it "should update Cut" do
      subject.cut.should_receive :update
      subject.import file
    end

    context "clear_cuts has been defined" do
      before do
        subject.clear_cuts!
      end

      it "should invoke Xport#clear_cuts before create a new cut" do
        subject.xport.should_receive(:clear_cuts).ordered.with(subject.number)
        subject.xport.should_receive(:import).ordered
        subject.import file
      end
    end

    context "clear_cuts hasn't been defined" do
      it "should not invoke Xport#clear_cuts" do
        subject.xport.should_not_receive(:create_cuts).with(subject.number)
        subject.import file
      end
    end

  end

  describe "#find_by_title" do

    let(:cart) { mock :title => "The Title of the Cart", :number => 123 }

    before(:each) do
      subject.stub_chain("xport.list_carts").and_return([cart])
    end

    it "should find an exact title" do
      subject.find_by_title(cart.title)
      subject.number.should == cart.number
    end

    it "should find with a 'matching' filename ('the-title_of_the Cart' for 'The Title of the Cart')" do
      subject.find_by_title("the-title_of_the Cart")
      subject.number.should == cart.number
    end

    it "should use specified options to find carts" do
      subject.xport.should_receive(:list_carts).with(:group => "TEST").and_return([cart])
      subject.find_by_title("dummy", :group => "TEST")
    end

    it "should add the import option :use_metadata => false" do
      subject.find_by_title(cart.title)
      subject.import_options[:use_metadata].should be_false
    end

  end

  describe "#clear_cuts!" do

    before do
      subject.number = 123
    end

    it "should set flag clear_cuts" do
      subject.clear_cuts!
      subject.clear_cuts.should be_true
    end

  end

  describe "#attributes" do

    it "should include clear_cuts value" do
      subject.clear_cuts = true
      subject.attributes["clear_cuts"].should == subject.clear_cuts
    end

    it "should include import_options value" do
      subject.import_options = { :use_metadata => false }
      subject.attributes["import_options"].should == { :use_metadata => false }
    end

    it "should include cut attributes" do
      subject.cut.days = %{mon}
      subject.attributes["cut"].should == { "days" => %{mon} }
    end

    it "should include scheduler codes" do
      subject.scheduler_codes << "dummy"
      subject.attributes["scheduler_codes"].should == ["dummy"]
    end

  end

  describe "#to_json" do

    it "should not include root" do
      subject.cut.days = %{mon}
      subject.to_json.should == '{"cut":{"days":"mon"}}'
    end

  end

  describe "#attributes=" do

    it "should set cut attributes" do
      subject.attributes = { "cut" => { "days" => %{mon} } }
      subject.cut.days.should == %{mon}
    end

  end

  describe "#updaters" do

    it "should contain ApiUpdater" do
      subject.updaters.should include(Rivendell::Import::Cart::ApiUpdater)
    end

    it "should not contain ApiUpdater if scheduler codes is defined" do
      subject.scheduler_codes << "dummy"
      subject.updaters.should_not include(Rivendell::Import::Cart::ApiUpdater)
    end

    it "should contain DbUpdater if Database is enabled" do
      Rivendell::Import::Database.stub :enabled? => true
      subject.updaters.should include(Rivendell::Import::Cart::DbUpdater)
    end

    it "should not contain DbUpdater if Database isn't enabled" do
      Rivendell::Import::Database.stub :enabled? => false
      subject.updaters.should_not include(Rivendell::Import::Cart::DbUpdater)
    end

  end

  describe "#update" do

    def updater(success = true)
      double(:new => mock(:update => success))
    end

    it "should return true if an Updater is successful" do
      subject.stub :updaters => [updater(false), updater(true)]
      subject.update.should be_true
    end

    it "should return true if all Updaters are not successful" do
      subject.stub :updaters => [updater(false)]
      subject.update.should be_false
    end

    it "should return false when no Updater is available" do
      subject.stub :updaters => []
      subject.update.should be_false
    end

  end

end

describe Rivendell::Import::Cart::Updater do

  let(:task) { mock }
  let(:cart) { Rivendell::Import::Cart.new task }
  subject { Rivendell::Import::Cart::Updater.new cart }

  describe "#empty_title?" do

    it "should true when title is nil" do
      subject.empty_title?(nil).should be_true
    end

    it "should true when title is '[new cart]'" do
      subject.empty_title?('[new cart]').should be_true
    end

    it "should false when title is anything else" do
      subject.empty_title?('dummy').should be_false
    end

  end

  describe "#update" do

    it "should return false if update! raises an error" do
      subject.stub(:update!).and_raise("fail")
      subject.update.should be_false
    end

    it "should return true if update! returns true" do
      subject.stub :update! => true
      subject.update.should be_true
    end

    it "should return false if update! returns false" do
      subject.stub :update! => false
      subject.update.should be_false
    end

  end

  describe "#title_with_default" do

    context "when Cart title is defined" do

      before { cart.title = "dummy" }

      it "should use this Cart title" do
        subject.title_with_default.should == cart.title
      end

    end

    context "when default title is defined" do

      before { cart.default_title = "dummy" }

      it "should default title if current title is empty" do
        subject.stub current_title: "[new cart]"
        subject.title_with_default.should == cart.default_title
      end

      it "should not use default title if current title is not empty" do
        subject.stub current_title: "Dummy"
        subject.title_with_default.should be_nil
      end

    end

  end

end

describe Rivendell::Import::Cart::ApiUpdater do

  let(:task) { mock }
  let(:cart) { Rivendell::Import::Cart.new task }
  subject { Rivendell::Import::Cart::ApiUpdater.new cart }

  let(:xport) { mock }

  before do
    subject.stub xport: xport
  end

  describe "#current_title" do

    it "should retrive the current title via the API" do
      xport_cart = mock(title: "dummy")
      xport.should_receive(:list_cart).with(cart.number).and_return(xport_cart)
      subject.current_title.should == xport_cart.title
    end

  end

  describe "#attributes" do

    it "should use title with default" do
      subject.stub title_with_default: "dummy"
      subject.attributes.should == { title: subject.title_with_default }
    end

    it "should not contain title when title_with_default is nil" do
      subject.stub title_with_default: nil
      subject.attributes.should == {}
    end

    it "should contain artist if defined" do
      cart.artist = "dummy"
      subject.attributes[:artist].should == subject.artist
    end

    it "should not contain artist if not defined" do
      cart.artist = nil
      subject.attributes.should_not have_key(:artist)
    end

    it "should contain album if defined" do
      cart.album = "dummy"
      subject.attributes[:album].should == subject.album
    end

    it "should not contain album if not defined" do
      cart.album = nil
      subject.attributes.should_not have_key(:album)
    end

  end

  describe "#update!" do

    context "when attributes is not empty" do

      it "should invoke xport edit_cart with attributes" do
        subject.stub attributes: { title: "dummy" }
        xport.should_receive(:edit_cart).with(cart.number, subject.attributes)
        subject.update!
      end

    end

    context "when attributes is empty" do

      it "should not invoke xport edit_cart" do
        subject.stub attributes: {}
        xport.should_not_receive(:edit_cart)
        subject.update!.should be_true
      end

    end

  end

end

describe Rivendell::Import::Cart::DbUpdater do

  let(:task) { mock }
  let(:cart) { Rivendell::Import::Cart.new task }
  subject { Rivendell::Import::Cart::DbUpdater.new cart }

  let(:db_cart) { Rivendell::DB::Cart.new }

  before do
    Rivendell::Import::Database.stub init: true
    db_cart.stub save: true
    Rivendell::DB::Cart.stub get: db_cart
  end

  describe "#current_cart" do

    it "should get cart with its number" do
      Rivendell::DB::Cart.should_receive(:get).with(cart.number).and_return(db_cart)
      subject.current_cart.should == db_cart
    end

  end

  describe "#current_title" do

    it "should return current_cart title" do
      db_cart.stub title: "dummy"
      subject.current_title.should == db_cart.title
    end

  end

  describe "#update!" do

    it "should init database" do
      Rivendell::Import::Database.should_receive :init
      subject.update!
    end

    it "should use title_with_default as Cart title" do
      subject.stub title_with_default: "dummy"
      subject.update!
      db_cart.title.should == subject.title_with_default
    end

    it "should use artist as Cart artist" do
      subject.stub artist: "dummy"
      subject.update!
      db_cart.artist.should == subject.artist
    end

    it "should use album as Cart album" do
      subject.stub album: "dummy"
      subject.update!
      db_cart.album.should == subject.album
    end

    it "should define scheduler_codes" do
      subject.stub scheduler_codes: ["dummy"]
      subject.update!
      db_cart.scheduler_codes.should == subject.scheduler_codes
    end

  end

end
