module NagiosAnalyzer
  class Status
    attr_accessor :last_updated, :scopes

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
      @last_updated = Time.at(File.mtime(statusfile))
      #scope is an array of lambda procs : it evaluates to true if service has to be displayed
      @scopes = []
      @scopes << lambda { |section| !section.include?("current_state=#{STATE_OK}") } unless options[:include_ok]
      @scopes << options[:scope] if options[:scope].is_a?(Proc)
    end
  
    def sections
      # don't try to instanciate each section ! on my conf (85hosts/700services),
      # it makes the script more 10 times slower (0.25s => >3s)
      @sections ||= File.read(@file).split("\n\n")
    end

    def host_items
      @host_items ||= sections.map do |s|
        Section.new(s) if s.start_with?("hoststatus") && in_scope?(s)
      end.compact.sort
    end

    def service_items
      @service_items ||= sections.map do |s|
        Section.new(s) if s.start_with?("servicestatus") && in_scope?(s)
      end.compact.sort
    end

    def items
      @items ||= (host_items + service_items).sort
    end

    def host_problems
      @host_problems ||= sections.map do |s|
        Section.new(s) if s.start_with?("hoststatus") && in_scope?(s) && problem?(s)
      end.compact.sort
    end

    def service_problems
      @service_problems ||= sections.map do |s|
        Section.new(s) if s.start_with?("servicestatus") && in_scope?(s) && problem?(s)
      end.compact.sort
    end

    def in_scope?(section)
      @scopes.inject(true) do |memo,condition|
        memo && condition.call(section)
      end
    end

    def problem?(section)
      section.match(/current_state=(\d+)/) && $1.to_i != STATE_OK
    end

    def reset_cache!
      @items = @service_items = @host_items = nil
    end
  end
end
