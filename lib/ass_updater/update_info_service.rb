#-- encoding utf-8

class AssUpdater
  # @abstract
  # @note Service http://downloads.1c.ru often unavailable and initialize fail
  #  on timeout. Don't worry and try again.
  class UpdateInfoService
    attr_reader :ass_updater

    # @param ass_updater [AssUpdater] owner objec
    def initialize(ass_updater)
      @ass_updater = ass_updater
      raw
    end

    private

    # Return raw data
    # @return [Hash]
    def raw
      @raw ||= parse
    end

    def updateinfo_base
      AssUpdater::UPDATEINFO_BASE
    end

    def updateinfo_path
      "#{updateinfo_base}/#{ass_updater.conf_code_name}/"\
        "#{ass_updater.conf_redaction.sub('.', '')}/"\
        "#{ass_updater.platform_version.sub('.', '')}/"
    end

    def parse
      fail 'Abstract method called'
    end
  end
end
