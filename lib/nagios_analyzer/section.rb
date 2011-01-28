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
        self[:status] = Status::STATES[self[:current_state]]
      else
        self[:status] = (self[:current_state] == Status::STATE_OK ? "OK" : "CRITICAL")
      end
    end

    def <=>(other)
      self.sort_array <=> other.sort_array
    end

    def sort_array
      [ (self[:type] == "servicestatus" ? 1 : 0),
        Status::STATES_ORDER[self[:current_state]].to_i,
        self[:host_name],
        self[:service_description].to_s ]
    end
  end
end
