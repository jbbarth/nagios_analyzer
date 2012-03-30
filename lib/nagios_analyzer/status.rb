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
      section_items(:hoststatus)
    end

    def service_items
      section_items(:servicestatus)
    end

    def items
      @items ||= (host_items + service_items)
    end

    def contactstatus_items
      section_items(:contactstatus)
    end

    def hostcomment_items
      section_items(:hostcomment)
    end

    def hostdowntime_items
      section_items(:hostdowntime)
    end

    def hoststatus_items
      section_items(:hoststatus)
    end

    def info_items
      section_items(:info)
    end

    def programstatus_items
      section_items(:programstatus)
    end

    def servicecomment_items
      section_items(:servicecomment)
    end

    def servicedowntime_items
      section_items(:servicedowntime)
    end

    def servicestatus_items
      section_items(:servicestatus)
    end

    def host_problems
      section_items(:hoststatus, true)
    end

    def service_problems
      section_items(:servicestatus, true)
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
      @items = nil
      [
        :contactstatus,
        :hostcomment,
        :hostdowntime,
        :hoststatus,
        :info,
        :programstatus,
        :servicecomment,
        :servicedowntime,
        :servicestatus,
      ].each do |name|
        self.instance_variable_set(section_var_sym(name, true), nil)
        self.instance_variable_set(section_var_sym(name, false), nil)
      end
    end

  private

    def section_items(name, filter_problems = false)
      var_sym = section_var_sym(name, filter_problems)
      if !self.instance_variable_get(var_sym)
        map = sections.map do |s|
          Section.new(s) if s =~ regexp_for_section(name) && in_scope?(s) && (!filter_problems || problem?(s))
        end.compact
        self.instance_variable_set(var_sym, map)
      end
      self.instance_variable_get(var_sym)
    end
    
    def regexp_for_section(name)
      Regexp.new("^\\s*#{name}\\s*{")
    end
    
    def section_var_sym(name, filter_problems)
      "@#{name}_#{filter_problems}".to_sym
    end
  end
end
