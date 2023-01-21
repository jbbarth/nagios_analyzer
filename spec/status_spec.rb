require File.expand_path('../spec_helper',__FILE__)

describe NagiosAnalyzer::Status do
  before(:each) do
    @file = File.expand_path('../data/status.dat',__FILE__)
  end

  let(:status) { NagiosAnalyzer::Status.new(@file, :include_ok => true) }

  it "creates a NagiosAnalyzer::Status object" do
    status.should be
    status.sections.should be_a(Array)
    status.sections.first.should include("created=")
    status.sections.length.should equal(6)
  end

  it "provides a last_updated attribute" do
    status.last_updated.should be_a(Time)
  end

  context "#scopes" do
    it "provides scopes to filter sections" do
      status.sections.length.should equal(6)
      status.scopes.length.should equal(0)
    end

    it "tells if a section is in the scopes" do
      status.scopes << lambda{|s|s.include?("host_name=server-web")}
      status.in_scope?(status.sections[2]).should be_truthy
      status.in_scope?(status.sections[3]).should be_falsey
    end

    it "defines scope in the initialization" do
      status = NagiosAnalyzer::Status.new(@file, :include_ok => true,
                                          :scope => lambda{|s|s.include?("host_name=server-web")})
      status.in_scope?(status.sections[2]).should be_truthy
      status.in_scope?(status.sections[3]).should be_falsey
    end
  end

  context "#items, #service_items, #host_items, #hostcomment_items" do
    it "returns all items" do
      status.sections.length.should equal(6)
      status.items.length.should equal(4)         #don't return info{} and programstatus{} sections
      status.items.first.should be_a(NagiosAnalyzer::Section)
    end

    it "returns host items" do
      status.host_items.length.should equal(2)    #4 = 2 host_items
      status.host_items.first[:type].should == "hoststatus"
    end

    it "returns service items" do
      status.service_items.length.should equal(2) # ... + 2 service_items
      status.service_items.first[:type].should == "servicestatus"
    end

    it "returns only service problems, keeping scopes on every items" do
      status.service_problems.length.should equal(1)
      status.service_items.length.should equal(2)
    end

    it "returns host problems, currently none" do
      status.host_problems.length.should equal(0)
    end

    it "resets cached attributes" do
      status.items.length.should equal(4)
      status.scopes << lambda{|s| s.start_with?("servicestatus")}
      status.items.length.should equal(4)
      status.reset_cache!
      status.items.length.should equal(2)
      status.host_items.length.should equal(0)
      status.service_items.length.should equal(2)
    end
  end

  context "without :include_ok option" do
    it "should filter items" do
      status = NagiosAnalyzer::Status.new(@file)
      status.items.length.should equal(1)         #don't return info{} and programstatus{} sections
      status.host_items.length.should equal(0)    #4 = 2 host_items
      status.service_items.length.should equal(1) # ... + 2 service_items
	  status.service_items.first.current_state.should_not equal(0)
    end
  end

  context "more status" do
    before(:each) do
      @file = File.expand_path('../data/morestatus.dat',__FILE__)
    end

    it "sould have lists for all kinds of nagios sections" do
      status.contactstatus_items.length.should equal(1)
      status.hostcomment_items.length.should equal(1)
      status.hostdowntime_items.length.should equal(1)
      status.hoststatus_items.length.should equal(1)
      status.info_items.length.should equal(1)
      status.programstatus_items.length.should equal(1)
      status.servicecomment_items.length.should equal(1)
      status.servicedowntime_items.length.should equal(1)
      status.servicestatus_items.length.should equal(1)
    end

    it "sould properly classify each kind of nagios sections" do
      status.contactstatus_items.first.id_for_testing.should == 1
      status.hostcomment_items.first.id_for_testing.should == 2
      status.hostdowntime_items.first.id_for_testing.should == 3
      status.hoststatus_items.first.id_for_testing.should == 4
      status.info_items.first.id_for_testing.should == 5
      status.programstatus_items.first.id_for_testing.should == 6
      status.servicecomment_items.first.id_for_testing.should == 7
      status.servicedowntime_items.first.id_for_testing.should == 8
      status.servicestatus_items.first.id_for_testing.should == 9
    end
  end

  context "parsing sections" do
    it "parses sections when they are appart" do
      status = status_for_data <<-DAT
        hoststatus {
          host_name=abc
          }


        hoststatus {
          host_name=abc
          }
      DAT
      status.hoststatus_items.size.should == 2
    end

    it "parses when sections are close by" do
      status = status_for_data <<-DAT
        hoststatus {
          host_name=abc
          }
        hoststatus {
          host_name=abc
          }
      DAT
      status.hoststatus_items.size.should == 2
    end

    def status_for_data(data)
      filename = "fixture.dat"
      File.stub(:mtime).with(filename).and_return(Time.now)
      File.stub(:read).with(filename).and_return(data)
      NagiosAnalyzer::Status.new(filename, :include_ok => true)
    end
  end
end
