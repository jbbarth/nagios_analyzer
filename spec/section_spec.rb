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
    expect(@section).to be_a(NA::Section)
    expect(@section.keys.map(&:class).uniq).to eq([Symbol])
  end

  it "parses a section" do
    expect(@section[:type]).to eq("servicestatus")
    expect(@section[:host_name]).to eq("server-web")
  end

  it "converts integers to Integer's" do
    expect(@section[:max_attempts]).to be_a(Integer)
    expect(@section[:max_attempts]).to eq(3)
  end

  it "provides a :status key to know the status" do
    expect(@section[:status]).to eq("WARNING")
    expect(NA::Section.new("servicestatus {\ncurrent_state=0\n}")[:status]).to eq("OK")
    expect(NA::Section.new("servicestatus {\ncurrent_state=2\n}")[:status]).to eq("CRITICAL")
    expect(NA::Section.new("servicestatus {\ncurrent_state=3\n}")[:status]).to eq("UNKNOWN")
    expect(NA::Section.new("hoststatus {\ncurrent_state=0\n}")[:status]).to eq("OK")
    expect(NA::Section.new("hoststatus {\ncurrent_state=42\n}")[:status]).to eq("CRITICAL")
  end

  it "properly parses sections with free text" do
    section = NA::Section.new("somethinghere {\n\tcomment_data=Free Text here. Possibly even with characters like } or = or even {.\n\nhello_prop=789321\n}")
    expect(section.type).to eq("somethinghere")
    expect(section.comment_data).to eq("Free Text here. Possibly even with characters like } or = or even {.")
    expect(section.hello_prop).to eq(789321)
  end

  it "properly parses sections with decimal values" do
    section = NA::Section.new("somethinghere {\n\nnumerical_value=3.141529\n}")
    expect(section.type).to eq("somethinghere")
    expect(section.numerical_value).to eq(3.141529)
  end

  context "direct access" do
    it "allows direct access to properties" do
      section = NA::Section.new("servicestatus {\ncurrent_state=2\n}")
      expect(section.current_state).to eq(2)
      expect(section.something_else).to be_nil
    end

    it "properly bubbles a NoMethodError when using inexistant methods" do
      section = NA::Section.new("servicestatus {\ncurrent_state=2\n}")
      expect { section.weird_inexistent_method(1) }.to raise_error(NoMethodError)
    end
  end

  context "#sort" do
    it "places servicestatus'es after hoststatus'es" do
      a = NA::Section.new("servicestatus {\ncurrent_state=0\n}")
      b = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      expect([a,b].sort).to eq([b,a])
    end

    it "places critical before unknown before warning before pending before dependent before ok" do
      host = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      critical = NA::Section.new("servicestatus {\ncurrent_state=2\n}")
      unknown = NA::Section.new("servicestatus {\ncurrent_state=3\n}")
      warning = NA::Section.new("servicestatus {\ncurrent_state=1\n}")
      dependent = NA::Section.new("servicestatus {\ncurrent_state=4\n}")
      ok = NA::Section.new("servicestatus {\ncurrent_state=0\n}")
      expect([ok, unknown, dependent, critical, host, warning].sort).to eq([host, critical, unknown, warning, dependent, ok])
    end

    it "sorts by host_name" do
      a = NA::Section.new("hoststatus {\ncurrent_state=0\nhost_name=a\n}")
      b = NA::Section.new("hoststatus {\ncurrent_state=0\nhost_name=b\n}")
      expect([b,a].sort).to eq([a,b])
    end

    it "sorts by service_description" do
      a = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      b = NA::Section.new("servicestatus {\ncurrent_state=0\nservice_description=b\n}")
      c = NA::Section.new("servicestatus {\ncurrent_state=0\nservice_description=c\n}")
      expect([c,b,a].sort).to eq([a,b,c])
    end

    it "has no problem even with missing fields (hostname don't have service_description)" do
      a = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      b = NA::Section.new("hoststatus {\ncurrent_state=0\n}")
      expect([a,b].sort).to eq([a,b])
    end
  end
end
