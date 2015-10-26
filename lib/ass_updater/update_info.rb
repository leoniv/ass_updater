#-- encoding utf-8

class AssUpdater
  #
  # Handle for UpdInfo.txt
  #
  class UpdateInfo < AssUpdater::UpdateInfoService
    UPDINFO_TXT = 'UpdInfo.txt'

    # Return last configuration release version from file UpdInfo.txt.
    # @note Service http://downloads.1c.ru often unavailable and it fail
    #  on timeout. Don't worry and try again.
    # @return [String]
    def version
      self[:version]
    end

    # Return value for key from UpdInfo.txt
    # @paran key [Symbol] :version, :from_versions, :update_date
    def [](key)
      @hash ||= parse
      @hash[key]
    end

  private

    def parse
      get =~ /Version=([\d\.]*)(\s*)FromVersions=[;]?([\d\.\;]*)(\s*)UpdateDate=([\d\.]*)/im
      r = { version: Regexp.last_match(1),
            from_versions: [],
            update_date: Regexp.last_match(5)
      }
      r[:from_versions] = Regexp.last_match(3).split(';') if Regexp.last_match(3)
      r
    end

    def get
      ass_updater.http.get("#{updateinfo_path}/#{UPDINFO_TXT}")
    end
  end
end
