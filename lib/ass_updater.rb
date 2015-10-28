#-- incoding utf-8
require 'zip'
require 'nori'
require 'ass_updater/version'

# AssUpdater - make easy download and install updates for 1C configuration from
# service http://dounloads.v8.1c.ru. For read more about 1C configurations
# visit site http://v8.1c.ru
class AssUpdater
  class Error < StandardError; end

  require 'ass_updater/ass_version'
  require 'ass_updater/http'
  require 'ass_updater/update_info_service'
  require 'ass_updater/update_info'
  require 'ass_updater/update_history'
  require 'ass_updater/update_distrib'

  PLATFORM_VERSIONS = { :"8.2" => '8.2', :"8.3" => '8.3' }
  KNOWN_CONF_CODENAME = { HRM: 'Зарплата и управление персоналом',
                          Accounting: 'Бухгалтерия предприятия',
                          AccountingKz: 'Бухгалтерия для Казахстана' }
  UPDATEREPO_BASE = 'http://downloads.v8.1c.ru/tmplts/'
  UPDATEINFO_BASE = 'http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/'
  UPD11_ZIP   = 'v8upd11.zip'

  # See arguments of {#initialize}
  # @return [String]
  attr_reader :conf_code_name, :conf_redaction, :platform_version
  # Object for access to 1C services. It's public for configure http connection.
  # @return [AssUpdater::HTTP]
  attr_accessor :http

  # @param conf_code_name [String] code name of configuration
  # @param conf_redaction [String] redaction is major version nuber of
  #  configuration. See {AssUpdater::AssVersion#redaction}
  # @param platform_version [String] major version namber of target platform
  #  1C:Enterprese.
  # @yield self. It's good place for configure http object. See
  #  {AssUpdater::HTTP}
  # @raise [AssUpdater::Error] if given invalid <conf_redaction> or
  #  <platform_version>
  def initialize(conf_code_name,
                 conf_redaction,
                 platform_version = PLATFORM_VERSIONS.keys.last
                )
    @conf_code_name = conf_code_name
    @http = AssUpdater::HTTP.new
    @conf_redaction = AssUpdater.valid_redaction(conf_redaction)
    @platform_version = AssUpdater.valid_platform_version(platform_version)
    yield self if block_given?
  end

  # Return info about last configuration release from file UpdInfo.txt
  # @note (see AssUpdater::UpdateInfo)
  # @return [AssUpdater::UpdateInfo]
  def update_info
    @update_info ||= AssUpdater::UpdateInfo.new(self)
  end

  # Return updates history from v8upd11.xml
  # @note (see AssUpdater::UpdateHistory)
  # @return [Hash]
  def update_history
    @update_history ||= AssUpdater::UpdateHistory.new(self)
  end

  # Evaluate versions required for update configuration
  # from version <from_ver> to version <to_ver>. Return array
  # iclude <to_ver> and exclude <from_ver> If called whithout
  # arguments return versions required for update from version
  # '0.0.0.0' to last release.
  # @param from_ver [String,AssUpdater::AssVersion] if nil from_ver set to
  #  '0.0.0.0'
  # @param to_ver [String,AssUpdater::AssVersion] if nill to_ver set to last
  #  release
  # @return [Array<AssUpdater::AssVersion>]
  # @raise [ArgumentError] if <from_ver> more then <to_ver>
  def required_versions_for_update(from_ver = nil, to_ver = nil)
    from_ver = AssUpdater::AssVersion.new(from_ver)
    to_ver = AssUpdater::AssVersion.new(to_ver || update_history.max_version)
    if from_ver >= to_ver
      fail ArgumentError, 'from_ver must be less than to_ver'
    end
    r = []
    c_ver = to_ver
    loop do
      r << c_ver
      targets = update_history.target c_ver
      break if targets.size == 0 || targets.index(from_ver)
      c_ver = targets.min
    end
    r
  end

  # (see AssUpdater::UpdateDistrib)
  # @note (see AssUpdater::UpdateDistrib#get)
  # @param user (see AssUpdater::UpdateDistrib#get)
  # @param password (see AssUpdater::UpdateDistrib#get)
  # @param version (see AssUpdater::UpdateDistrib#initialize)
  # @param tmplt_root (see AssUpdater::UpdateDistrib#initialize)
  # @return (see AssUpdater::UpdateDistrib#get)
  def get_update(user, password, version, tmplt_root)
    distrib = new_update_distrib(version, tmplt_root)
    distrib.get(user, password)
  end

  # Get updates included in array <versions>. See {#get_update}
  # @param user (see #get_update)
  # @param password (see #get_update)
  # @param versions [Array<String,AssUpdater::AssVersion>]
  # @param tmplt_root (see #get_update)
  # @return [Array<AssUpdater::UpdateDistrib>] returned {#get_update}
  # @yield [AssUpdater::UpdateDistrib] for each getted distrib
  def get_updates(user, password, versions, tmplt_root)
    r = []
    versions.each do |version|
      r << get_update(user, password, version, tmplt_root)
      yield r.last if block_given?
    end
    r
  end

  # Return versions all instaled updates finded in 1C templates directory
  # <tmplt_root>
  # @param tmplt_root (see #get_update)
  # @return [Array<AssUpdater::AssVersion>]
  def instaled_versions(tmplt_root)
    (Dir.entries(conf_distribs_local_path(tmplt_root)).map do |e|
      next if e == '.' || e == '..'
      begin
        v = AssUpdater::AssVersion.new(e.split('_').join('.'))
        v if v.redaction == conf_redaction
      rescue ArgumentError
        nil
      end
    end).compact
  end

  # Return all instaled updates findet in 1C templates directory
  # @note return distirbs present in {#update_history} only
  # @param tmplt_root (see #get_update)
  # @return [Array<AssUpdater::UpdateDistrib>]
  def instaled_distribs(tmplt_root)
    instaled_versions(tmplt_root).map do |v|
      begin
        new_update_distrib(v, tmplt_root)
      rescue AssUpdater::Error
        nil
      end
    end.compact
  end

  # Wrapper return UpdateDistrib object
  # @param version (see #get_update)
  # @param tmplt_root (see #get_update)
  # @return [AssUpdater::UpdateDistrib]
  def new_update_distrib(version, tmplt_root)
    AssUpdater::UpdateDistrib.new(version, tmplt_root, self)
  end

  private

  def conf_distribs_local_path(tmplt_root)
    File.join(tmplt_root, '1c', conf_code_name)
  end

  def self.valid_platform_version(v)
    unless PLATFORM_VERSIONS.key?(v.to_sym)
      fail AssUpdater::Error,
           "Invalid platform_version `#{v}'."\
           "Support #{PLATFORM_VERSIONS.keys.join(' | ')} versions only."
    end
    PLATFORM_VERSIONS[v.to_sym]
  end

  def self.valid_redaction(r)
    fail AssUpdater::Error, "Invalid redaction #{r}" unless r =~ /\d\.\d/
    r
  end
end
