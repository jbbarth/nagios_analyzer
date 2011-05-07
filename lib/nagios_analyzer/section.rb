module NagiosAnalyzer
  class Section
    def initialize(section)
      @section = section.strip
    end

    def method_missing(method, *args)
      hash.send(method, *args)
    end

    def hash
      return @hash if @hash
      @hash = {}
      @section.each_line do |line|
        line.strip!
        if line.match(/(\S+) \{/)
          @hash[:type] = $1
        elsif line.match(/(\S+)=(.*)/) #more efficient than include?+split+join..
          @hash[$1.to_sym] = ($2 == "#{$2.to_i}" ? $2.to_i : $2)
        end
      end
      if @hash[:type] == "servicestatus"
        @hash[:status] = Status::STATES[@hash[:current_state]]
      else
        @hash[:status] = (@hash[:current_state] == Status::STATE_OK ? "OK" : "CRITICAL")
      end
      @hash
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
