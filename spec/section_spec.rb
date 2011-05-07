require File.expand_path('../spec_helper',__FILE__)

describe NagiosAnalyzer::Section do
  include NagiosAnalyzer

  before(:each) do
    file = File.expand_path('../data/status.dat',__FILE__)
    status = Status.new(file)
    @section = status.service_items.first
  end

  it "returns a hash with keys only" do
    @section.should be_a(Section)
    @section.keys.map(&:class).uniq.should == [Symbol]
  end

  it "parses a section" do
    @section[:type].should == "servicestatus"
    @section[:host_name].should == "server-web"
  end

  it "converts integers to Integer's" do
    @section[:max_attempts].should be_a(Integer)
    @section[:max_attempts].should == 3
  end

  it "provides a :status key to know the status" do
    @section[:status].should == "WARNING"
    Section.new("servicestatus {\ncurrent_state=0\n}")[:status].should == "OK"
    Section.new("servicestatus {\ncurrent_state=2\n}")[:status].should == "CRITICAL"
    Section.new("servicestatus {\ncurrent_state=3\n}")[:status].should == "UNKNOWN"
    Section.new("hoststatus {\ncurrent_state=0\n}")[:status].should == "OK"
    Section.new("hoststatus {\ncurrent_state=42\n}")[:status].should == "CRITICAL"
  end

  context "#sort" do
    it "places servicestatus'es after hoststatus'es" do
      a = Section.new("servicestatus {\ncurrent_state=0\n}")
      b = Section.new("hoststatus {\ncurrent_state=0\n}")
      [a,b].sort.should == [b,a]
    end

    it "places critical before unknown before warning before pending before dependent before ok" do
      host = Section.new("hoststatus {\ncurrent_state=0\n}")
      critical = Section.new("servicestatus {\ncurrent_state=2\n}")
      unknown = Section.new("servicestatus {\ncurrent_state=3\n}")
      warning = Section.new("servicestatus {\ncurrent_state=1\n}")
      dependent = Section.new("servicestatus {\ncurrent_state=4\n}")
      ok = Section.new("servicestatus {\ncurrent_state=0\n}")
      [ok, unknown, dependent, critical, host, warning].sort.should == [host, critical, unknown, warning, dependent, ok]
    end

    it "sorts by host_name" do
      a = Section.new("hoststatus {\ncurrent_state=0\nhost_name=a\n}")
      b = Section.new("hoststatus {\ncurrent_state=0\nhost_name=b\n}")
      [b,a].sort.should == [a,b]
    end

    it "sorts by service_description" do
      a = Section.new("hoststatus {\ncurrent_state=0\n}")
      b = Section.new("servicestatus {\ncurrent_state=0\nservice_description=b\n}")
      c = Section.new("servicestatus {\ncurrent_state=0\nservice_description=c\n}")
      [c,b,a].sort.should == [a,b,c]
    end

    it "has no problem even with missing fields (hostname don't have service_description)" do
      a = Section.new("hoststatus {\ncurrent_state=0\n}")
      b = Section.new("hoststatus {\ncurrent_state=0\n}")
      [a,b].sort.should == [a,b]
    end
  end
end
