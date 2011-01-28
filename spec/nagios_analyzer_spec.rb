require File.expand_path('../spec_helper',__FILE__)

describe NagiosAnalyzer::Status do
  it "creates a NagiosAnalyzer::Status object" do
    NagiosAnalyzer::Status.new.should be
  end
end
