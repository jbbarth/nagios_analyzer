require File.expand_path('../spec_helper',__FILE__)

describe NagiosAnalyzer::Status do
  before(:each) do
    @file = File.expand_path('../data/status.dat',__FILE__)
  end

  let(:status) { NagiosAnalyzer::Status.new(@file, :include_ok => true) }

  it "creates a NagiosAnalyzer::Status object" do
    expect(status).to be
    expect(status.sections).to be_a(Array)
    expect(status.sections.first).to include("created=")
    expect(status.sections.length).to equal(6)
  end

  it "provides a last_updated attribute" do
    expect(status.last_updated).to be_a(Time)
  end

  context "#scopes" do
    it "provides scopes to filter sections" do
      expect(status.sections.length).to equal(6)
      expect(status.scopes.length).to equal(0)
    end

    it "tells if a section is in the scopes" do
      status.scopes << lambda{|s|s.include?("host_name=server-web")}
      expect(status.in_scope?(status.sections[2])).to be_truthy
      expect(status.in_scope?(status.sections[3])).to be_falsey
    end

    it "defines scope in the initialization" do
      status = NagiosAnalyzer::Status.new(@file, :include_ok => true,
                                          :scope => lambda{|s|s.include?("host_name=server-web")})
      expect(status.in_scope?(status.sections[2])).to be_truthy
      expect(status.in_scope?(status.sections[3])).to be_falsey
    end
  end

  context "#items, #service_items, #host_items, #hostcomment_items" do
    it "returns all items" do
      expect(status.sections.length).to equal(6)
      expect(status.items.length).to equal(4)         #don't return info{} and programstatus{} sections
      expect(status.items.first).to be_a(NagiosAnalyzer::Section)
    end

    it "returns host items" do
      expect(status.host_items.length).to equal(2)    #4 = 2 host_items
      expect(status.host_items.first[:type]).to eq("hoststatus")
    end

    it "returns service items" do
      expect(status.service_items.length).to equal(2) # ... + 2 service_items
      expect(status.service_items.first[:type]).to eq("servicestatus")
    end

    it "returns only service problems, keeping scopes on every items" do
      expect(status.service_problems.length).to equal(1)
      expect(status.service_items.length).to equal(2)
    end

    it "returns host problems, currently none" do
      expect(status.host_problems.length).to equal(0)
    end

    it "resets cached attributes" do
      expect(status.items.length).to equal(4)
      status.scopes << lambda{|s| s.start_with?("servicestatus")}
      expect(status.items.length).to equal(4)
      status.reset_cache!
      expect(status.items.length).to equal(2)
      expect(status.host_items.length).to equal(0)
      expect(status.service_items.length).to equal(2)
    end
  end

  context "without :include_ok option" do
    it "should filter items" do
      status = NagiosAnalyzer::Status.new(@file)
      expect(status.items.length).to equal(1)         #don't return info{} and programstatus{} sections
      expect(status.host_items.length).to equal(0)    #4 = 2 host_items
      expect(status.service_items.length).to equal(1) # ... + 2 service_items
      expect(status.service_items.first.current_state).to_not equal(0)
    end
  end

  context "more status" do
    before(:each) do
      @file = File.expand_path('../data/morestatus.dat',__FILE__)
    end

    it "sould have lists for all kinds of nagios sections" do
      expect(status.contactstatus_items.length).to equal(1)
      expect(status.hostcomment_items.length).to equal(1)
      expect(status.hostdowntime_items.length).to equal(1)
      expect(status.hoststatus_items.length).to equal(1)
      expect(status.info_items.length).to equal(1)
      expect(status.programstatus_items.length).to equal(1)
      expect(status.servicecomment_items.length).to equal(1)
      expect(status.servicedowntime_items.length).to equal(1)
      expect(status.servicestatus_items.length).to equal(1)
    end

    it "sould properly classify each kind of nagios sections" do
      expect(status.contactstatus_items.first.id_for_testing).to eq(1)
      expect(status.hostcomment_items.first.id_for_testing).to eq(2)
      expect(status.hostdowntime_items.first.id_for_testing).to eq(3)
      expect(status.hoststatus_items.first.id_for_testing).to eq(4)
      expect(status.info_items.first.id_for_testing).to eq(5)
      expect(status.programstatus_items.first.id_for_testing).to eq(6)
      expect(status.servicecomment_items.first.id_for_testing).to eq(7)
      expect(status.servicedowntime_items.first.id_for_testing).to eq(8)
      expect(status.servicestatus_items.first.id_for_testing).to eq(9)
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
      expect(status.hoststatus_items.size).to eq(2)
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
      expect(status.hoststatus_items.size).to eq(2)
    end

    def status_for_data(data)
      filename = "fixture.dat"
      allow(File).to receive(:mtime).with(filename).and_return(Time.now)
      allow(File).to receive(:read).with(filename).and_return(data)
      NagiosAnalyzer::Status.new(filename, :include_ok => true)
    end
  end
end
