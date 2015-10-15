class AssUpdater
  class AssVersion

    attr_reader :_1,:_2,:_3,:_4

    class << self

     def zerro_version
        self.new("0.0.0.0")
      end

      def convert_array(a)
        a.map do |i|
          self.new(i)
        end
      end
    end

    def zerro?
      self.to_s == "0.0.0.0"
    end

    def initialize(v=nil)
      v ||= "0.0.0.0"
      raise ArgumentError.new "Invalid version string `#{v}'. Expect 'd.d.d.d' format" unless v.to_s =~ /^(\d)+\.(\d+)\.(\d+)\.(\d+)$/
      @_1 = $1.to_i
      @_2 = $2.to_i
      @_3 = $3.to_i
      @_4 = $4.to_i
    end

    def to_a
      [@_1,@_2,@_3,@_4]
    end

    def to_s
      self.to_a.join(".")
    end

    def redaction
      self.to_a.shift(2).join(".")
    end

    def distrib_path(tmpl_root,vendor,conf_code_name)
      File.join(tmpl_root,vendor,conf_code_name,self.to_a.join("_"))
    end

    def <=> other_version
      merge(other_version).each do |v|
        if v[0] > v[1]
          return 1
        elsif v[0] < v[1]
          return -1
        end
      end
     return 0
    end

    def == other_version
        (self <=> other_version) == 0
    end

    def > other_version
      (self <=> other_version) == 1
    end

    def < other_version
      (self <=> other_version) == -1
    end

    def >= other_version
      (self <=> other_version) >=0
    end

    def <= other_version
      (self <=> other_version) <=0
    end

    private

    def merge(o)
      self.to_a.zip o.to_a
    end

  end
end
