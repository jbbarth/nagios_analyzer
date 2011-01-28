module NagiosAnalyzer
  class Status
    STATE_OK = 0
    STATES = {
      0 => "OK",
      1 => "WARNING",
      2 => "CRITICAL",
      3 => "UNKNOWN",
      4 => "DEPENDENT"
    }
    STATES_ORDER = {
      2 => 0, #critical => first etc.
      3 => 1,
      1 => 2,
      4 => 3,
      0 => 4
    }
  
    def initialize(statusfile, options = {})
      @file = statusfile
      sections #loads section at this point so we raise immediatly if file has a item
    end
  
    def sections
      # don't try to instanciate each section ! on my conf (85hosts/700services),
      # it makes the script more 10 times slower (0.25s => >3s)
      @sections ||= File.read(@file).split("\n\n")
    end
  end
end
