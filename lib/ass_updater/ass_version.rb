class AssUpdater
  class AssVersion
    attr_reader :_1, :_2, :_3, :_4

    class << self
      def zerro_version
        new('0.0.0.0')
      end

      def convert_array(a)
        a.map do |i|
          new(i)
        end
      end
    end

    def zerro?
      to_s == '0.0.0.0'
    end

    def initialize(v = nil)
      v ||= '0.0.0.0'
      unless v.to_s =~ /^(\d)+\.(\d+)\.(\d+)\.(\d+)$/
        fail ArgumentError,
             "Invalid version string `#{v}'. Expect 'd.d.d.d' format"
      end
      @_1 = Regexp.last_match(1).to_i
      @_2 = Regexp.last_match(2).to_i
      @_3 = Regexp.last_match(3).to_i
      @_4 = Regexp.last_match(4).to_i
    end

    def to_a
      [@_1, @_2, @_3, @_4]
    end

    def to_s
      to_a.join('.')
    end

    def redaction
      to_a.shift(2).join('.')
    end

    def distrib_path(tmpl_root, vendor, conf_code_name)
      File.join(tmpl_root, vendor, conf_code_name, to_a.join('_'))
    end

    def <=>(other)
      merge(other).each do |v|
        if v[0] > v[1]
          return 1
        elsif v[0] < v[1]
          return -1
        end
      end
      0
    end

    def ==(other)
      (self <=> other) == 0
    end

    def >(other)
      (self <=> other) == 1
    end

    def <(other)
      (self <=> other) == -1
    end

    def >=(other)
      (self <=> other) >= 0
    end

    def <=(other)
      (self <=> other) <= 0
    end

    private

    def merge(o)
      to_a.zip o.to_a
    end
  end
end
