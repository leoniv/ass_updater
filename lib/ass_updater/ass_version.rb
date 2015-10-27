class AssUpdater
  # Class implement 1C version numbering. 1C version consist from 4 digt group.
  # Major 1st and 2nd group called *Redaction*.
  class AssVersion
    # Value of digit group
    # @return [Fixrnum]
    attr_reader :_1, :_2, :_3, :_4

    class << self
      # Return zerro vesion number '0.0.0.0'
      # @return [AssUpdater::AssVersion]
      def zerro_version
        new('0.0.0.0')
      end

      # Convert [Array<String>] to [Array<AssUpdater::AssVersion>]
      # @return [Array<AssUpdater::AssVersion>]
      def convert_array(a)
        a.map do |i|
          new(i)
        end
      end
    end

    # Return true if it is zerro version see
    # {.zerro_version}
    def zerro?
      to_s == '0.0.0.0'
    end

    # @param v [String AssUpdater::AssVersion] if not given return
    #  {.zerro_version}
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

    # Conver version to array of digit group
    # @return [Array<Fixnum>]
    def to_a
      [@_1, @_2, @_3, @_4]
    end

    # Convert version to string
    # @return [Stgring]
    def to_s
      to_a.join('.')
    end

    # Return redaction number
    # @return [String]
    def redaction
      to_a.shift(2).join('.')
    end

    # Compare versions
    # @return [Boollean]
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

    # (see #<=>)
    def ==(other)
      (self <=> other) == 0
    end

    # (see #<=>)
    def >(other)
      (self <=> other) == 1
    end

    # (see #<=>)
    def <(other)
      (self <=> other) == -1
    end

    # (see #<=>)
    def >=(other)
      (self <=> other) >= 0
    end

    # (see #<=>)
    def <=(other)
      (self <=> other) <= 0
    end

    private

    def merge(o)
      to_a.zip o.to_a
    end
  end
end
