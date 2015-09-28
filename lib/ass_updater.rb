require "ass_updater/version"

class AssUpdater
  class Error < StandartError; end
  class Runtime < AssUpdater::Error; end
  PLATFORM_VERSIONS = ["8.2","8.3"]
  attr_reader user,pass,conf_code_name,conf_redaction,platform_version
  def initialize(user,pass,conf_code_name,conf_redaction,platform_version=PLATFORM_VERSIONS.last)
    @user=user
    @pass=pass
    @conf_code_name=conf_code_name
    @conf_redaction=conf_redaction
    @platform_version=valid_platform_version(platform_version)
  end

  def valid_platform_version(v)
    raise Error "Invalid platform_version `#{v}'. Support #{PLATFORM_VERSIONS.join(" | ")} versions only."
  end


end
