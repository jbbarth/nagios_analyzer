module NagiosAnalyzer
  class Section
    def initialize(section)
      @section = section.strip
    end

    def method_missing(method, *args)
      begin
        hash.send(method, *args)
      rescue NoMethodError => e
        raise e if args.size > 0
        hash[method]
      end
    end

    #explicitly define NagiosAnalyzer::Section#type method in ruby 1.8
    #because it returns the class in this version, hence not triggers
    #method_missing to return our internal type.
    if RUBY_VERSION == "1.8.7"
      def type
        hash[:type]
      end
    end

    def to_hash
      return @hash if @hash
      @hash = {}
      @section.each_line do |line|
        line.strip!
        if line.match(/^\s*([a-zA-Z0-9]*)\s*\{/)
          @hash[:type] = $1
        elsif line.match(/(\S+)=(.*)/) #more efficient than include?+split+join..
          property, value = ["#{$1}", "#{$2}"]
          @hash[property.to_sym] =
            case
            when value.strip =~ /^[0-9]+$/ then value.to_i
            when value.strip =~ /^[0-9.]+$/ then value.to_f
            else value
            end
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
        self[:host_name].to_s,
        self[:service_description].to_s ]
    end
  end
end
