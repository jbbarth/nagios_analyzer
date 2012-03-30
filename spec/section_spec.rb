require File.expand_path('../spec_helper',__FILE__)

#alias NagiosAnalyzer to NA for convenience
NA = NagiosAnalyzer

describe NA::Section do
  before(:each) do
    file = File.expand_path('../data/status.dat',__FILE__)
    status = NA::Status.new(file)
    @section = status.service_items.first
  end

  it "returns a hash with keys only" do
    @section.should be_a(NA::Section)
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
    NA::Section.new("servicestatus {\ncurrent_state=0\n}")[:status].should == "OK"
    NA::Section.new("servicestatus {\ncurrent_state=2\n}")[:status].should == "CRITICAL"
    NA::Section.new("servicestatus {\ncurrent_state=3\n}")[:status].should == "UNKNOWN"
    NA::Section.new("hoststatus {\ncurrent_state=0\n}")[:status].should == "OK"
    NA::Section.new("hoststatus {\ncurrent_state=42\n}")[:status].should == "CRITICAL"
  end

  it "properly parses sections with free text" do
    section = NA::Section.new("somethinghere {\n\tcomment_data=Free Text here. Possibly even with characters like } or = or even {.\n\nhello_prop=789321\n}")
    section.type.should == "somethinghere"
    section.comment_data.should == "Free Text here. Possibly even with characters like } or = or even {."
    section.hello_prop.should == 789321
  end

  context "direct access" do
    it "allows direct access to properties" do
      section = NA::Section.new("servicestatus {\ncurrent_state=2\n}")
      section.current_state.should == 2
      section.something_else.should be_nil
    end

    it "properly bubbles a NoMethodError when using inexistant methods" do
      section = NA::Section.new("servicestatus {\ncurrent_state=2\n}")
      lambda { section.weird_inexistent_method(1) }.should raise_error NoMethodError
    end
  end

  context "#sort" do
    it "places servicestatus'es after hoststatus'es" do
      a = NA::Section.new("servicestatus {\ncurrent_state=0\n}")
      b = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      [a,b].sort.should == [b,a]
    end

    it "places critical before unknown before warning before pending before dependent before ok" do
      host = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      critical = NA::Section.new("servicestatus {\ncurrent_state=2\n}")
      unknown = NA::Section.new("servicestatus {\ncurrent_state=3\n}")
      warning = NA::Section.new("servicestatus {\ncurrent_state=1\n}")
      dependent = NA::Section.new("servicestatus {\ncurrent_state=4\n}")
      ok = NA::Section.new("servicestatus {\ncurrent_state=0\n}")
      [ok, unknown, dependent, critical, host, warning].sort.should == [host, critical, unknown, warning, dependent, ok]
    end

    it "sorts by host_name" do
      a = NA::Section.new("hoststatus {\ncurrent_state=0\nhost_name=a\n}")
      b = NA::Section.new("hoststatus {\ncurrent_state=0\nhost_name=b\n}")
      [b,a].sort.should == [a,b]
    end

    it "sorts by service_description" do
      a = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      b = NA::Section.new("servicestatus {\ncurrent_state=0\nservice_description=b\n}")
      c = NA::Section.new("servicestatus {\ncurrent_state=0\nservice_description=c\n}")
      [c,b,a].sort.should == [a,b,c]
    end

    it "has no problem even with missing fields (hostname don't have service_description)" do
      a = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      b = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      [a,b].sort.should == [a,b]
    end
  end
end
