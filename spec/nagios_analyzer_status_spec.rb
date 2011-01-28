require File.expand_path('../spec_helper',__FILE__)

describe NagiosAnalyzer::Status do
  before(:each) do
    @file = File.expand_path('../data/status.dat',__FILE__)
  end

  it "creates a NagiosAnalyzer::Status object" do
    s = NagiosAnalyzer::Status.new(@file)
    s.should be
    s.sections.should be_a(Array)
    s.sections.first.should include("created=")
  end
end
