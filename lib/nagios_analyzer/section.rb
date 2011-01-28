module NagiosAnalyzer
  class Section < ::Hash
    def initialize(section)
      section.strip!
      section.each_line do |line|
        line.strip!
        if line.match(/(\S+) \{/)
          self[:type] = $1
        elsif line.match(/(\S+)=(.*)/) #more efficient than include?+split+join..
          self[$1.to_sym] = ($2 == "#{$2.to_i}" ? $2.to_i : $2)
        end
      end
      if self[:type] == "servicestatus"
        self[:status] = NagiosAnalyzer::Status::STATES[self[:current_state]]
      else
        self[:status] = (self[:current_state] == NagiosAnalyzer::Status::STATE_OK ? "OK" : "CRITICAL")
      end
    end
  end
end
