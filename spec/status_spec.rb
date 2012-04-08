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
    status.should have(6).sections
  end

  it "provides a last_updated attribute" do
    status.last_updated.should be_a(Time)
  end

  context "#scopes" do
    it "provides scopes to filter sections" do
      status.should have(6).sections
      status.should have(0).scopes
    end

    it "tells if a section is in the scopes" do
      status.scopes << lambda{|s|s.include?("host_name=server-web")}
      status.in_scope?(status.sections[2]).should be_true
      status.in_scope?(status.sections[3]).should be_false
    end

    it "defines scope in the initialization" do
      status = NagiosAnalyzer::Status.new(@file, :include_ok => true,
                                          :scope => lambda{|s|s.include?("host_name=server-web")})
      status.in_scope?(status.sections[2]).should be_true
      status.in_scope?(status.sections[3]).should be_false
    end
  end

  context "#items, #service_items, #host_items, #hostcomment_items" do
    it "returns all items" do
      status.should have(6).sections
      status.should have(4).items         #don't return info{} and programstatus{} sections
      status.items.first.should be_a(NagiosAnalyzer::Section)
    end

    it "returns host items" do
      status.should have(2).host_items    #4 = 2 host_items
      status.host_items.first[:type].should == "hoststatus"
    end

    it "returns service items" do
      status.should have(2).service_items # ... + 2 service_items
      status.service_items.first[:type].should == "servicestatus"
    end

    it "returns only service problems, keeping scopes on every items" do
      status.should have(1).service_problems
      status.should have(2).service_items
    end

    it "returns host problems, currently none" do
      status.should have(0).host_problems
    end

    it "resets cached attributes" do
      status.should have(4).items
      status.scopes << lambda{|s| s.start_with?("servicestatus")}
      status.should have(4).items
      status.reset_cache!
      status.should have(2).items
      status.should have(0).host_items
      status.should have(2).service_items
    end
  end

  context "without :include_ok option" do
    it "should filter items" do
      status = NagiosAnalyzer::Status.new(@file)
      status.should have(1).items         #don't return info{} and programstatus{} sections
      status.should have(0).host_items    #4 = 2 host_items
      status.should have(1).service_items # ... + 2 service_items
      status.service_items.first.should_not include("current_state=0")
    end
  end

  context "more status" do
    before(:each) do
      @file = File.expand_path('../data/morestatus.dat',__FILE__)
    end

    it "sould have lists for all kinds of nagios sections" do
      status.contactstatus_items.should have(1).items
      status.hostcomment_items.should have(1).items
      status.hostdowntime_items.should have(1).items
      status.hoststatus_items.should have(1).items
      status.info_items.should have(1).items
      status.programstatus_items.should have(1).items
      status.servicecomment_items.should have(1).items
      status.servicedowntime_items.should have(1).items
      status.servicestatus_items.should have(1).items
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
      File.stub!(:mtime).with(filename).and_return(Time.now)
      File.stub!(:read).with(filename).and_return(data)
      NagiosAnalyzer::Status.new(filename, :include_ok => true)
    end
  end
end
