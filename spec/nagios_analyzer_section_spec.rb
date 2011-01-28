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
    @section.should be_a(Hash)
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
end
