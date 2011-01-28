require File.expand_path('../spec_helper',__FILE__)

describe NagiosAnalyzer::Status do
  before(:each) do
    @file = File.expand_path('../data/status.dat',__FILE__)
    @status = NagiosAnalyzer::Status.new(@file)
  end

  it "creates a NagiosAnalyzer::Status object" do
    @status.should be
    @status.sections.should be_a(Array)
    @status.sections.first.should include("created=")
  end

  it "provides a last_updated attribute" do
    @status.last_updated.should be_a(Time)
  end
end
