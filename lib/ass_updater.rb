#-- incoding utf-8
require 'zip'
require 'nori'
require 'ass_updater/version'

#
# AssUpdater - make easy download and install updates for 1C configuration from
# service http://dounloads.v8.1c.ru. For read more about 1C configurations
# visit site http://v8.1c.ru
#
class AssUpdater
  class Error < StandardError; end
  class HTTP; end
  class AssVersion; end

  require 'ass_updater/ass_version'
  require 'ass_updater/http'

  PLATFORM_VERSIONS = { :"8.2" => '82', :"8.3" => '83' }
  KNOWN_CONF_CODENAME = { HRM: 'Зарплата и управление персоналом',
                          Accounting: 'Бухгалтерия предприятия',
                          AccountingKz: 'Бухгалтерия для Казахстана' }
  UPDATEREPO_BASE = 'http://downloads.v8.1c.ru/tmplts/'
  UPDATEINFO_BASE = 'http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/'
  UPDINFO_TXT = 'UpdInfo.txt'
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

  # Return last configuration release version from file UpdInfo.txt.
  # @note Service http://downloads.1c.ru often unavailable and it fail
  #  on timeout. Don't worry and try again.
  # @return [String]
  def curent_vesrsion
    update_info[:version]
  end

  # Return info about last configuration release from file UpdInfo.txt
  # @note Service http://downloads.1c.ru often unavailable and it fail
  #  on timeout. Don't worry and try again.
  # @return [Hash]
  def update_info
    @update_info ||= AssUpdater.parse_updateinfo_txt(
      AssUpdater.get_update_info_text(self)
    )
    @update_info
  end

  # Return updates history from v8upd11.xml
  # @note Service http://downloads.1c.ru often unavailable and it fail
  #  on timeout. Don't worry and try again.
  # @return [Hash]
  def update_history
    @update_history ||= AssUpdater.parse_updatehistory_xml(
      AssUpdater.get_update_history_text(self)
    )
    @update_history
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
  def required_distrib_for_update(from_ver = nil, to_ver = nil)
    from_ver = AssUpdater::AssVersion.new(from_ver)
    to_ver = AssUpdater::AssVersion.new(to_ver || max_update_history_version)
    if from_ver >= to_ver
      fail ArgumentError, 'from_ver must be less than to_ver'
    end
    r = []
    c_ver = to_ver
    loop do
      r << c_ver
      targets = exclude_unknown_version(
        AssUpdater::AssVersion.convert_array(get_distrib_info(c_ver)['target'])
      )
      break if targets.size == 0 || targets.index(from_ver)
      c_ver = targets.min
    end
    r
  end

  # Download <version> distributive of configuration update and uzip into
  # <tmplt_root>. Exists in <template_root> distrib will be overwritten.
  # @note Require authorization.
  # @note Service http://downloads.v8.1c.ru
  #  often unavailable and it fail on timeout. Don't worry and try again.
  # @param user [String] authorization user name
  # @param password [String] authorization password
  # @param version [String,AssUpdater::AssVersion] disrib version
  # @param tmplt_root [String] path to 1C update templates
  # @return [String] path where distrib unzipped
  def get_distrib(user, password, version, tmplt_root)
    zip_f = Tempfile.new('1cv8_zip')
    begin
      download_distrib(zip_f, user, password, version)
      zip_f.rewind
      dest_dir = unzip_all(zip_f, version, tmplt_root)
    ensure
      zip_f.close
      zip_f.unlink
    end
    dest_dir
  end

  # Dounload and unzip all versions from array <versions>. See {#get_distrib}
  # @param user (see #get_distrib)
  # @param password (see #get_distrib)
  # @param versions [Array<String,AssUpdater::AssVersion>]
  # @param tmplt_root (see #get_distrib)
  # @return [Array] of pathes returned {#get_distrib}
  def get_distribs(user, password, versions, tmplt_root)
    r = []
    versions.each do |version|
      r << get_distrib(user, password, version, tmplt_root)
    end
    r
  end

  # Return all downloaded versions finded in 1C templates directory
  # <tmplt_root>
  # @param tmplt_root [String] path to 1C templates directory
  # @return [Array<AssUpdater::AssVersion>]
  def known_local_distribs(tmplt_root)
    (Dir.entries(conf_distribs_local_path(tmplt_root)).map do |e|
      next if e == '.' || e == '..'
      begin
        AssUpdater::AssVersion.new(e.split('_').join('.'))
      rescue ArgumentError
        nil
      end
    end).compact
  end

  # Returm min distrib version from {#update_history}
  # @return [AssUpdater::AssVersion]
  def min_update_history_version
    all_update_history_versions.min
  end

  # Return max distrib version from {#update_history}
  # @return [AssUpdater::AssVersion]
  def max_update_history_version
    all_update_history_versions.max
  end

  # Return all versions from {#update_history}
  # @return [Array<AssUpdater::AssVersion>]
  def all_update_history_versions
    r = []
    update_history['update'].each do |h|
      r << h['version']
    end
    AssUpdater::AssVersion.convert_array r
  end

  private

  def unzip_all(zip_f, version, tmplt_root)
    dest_dir = ''
    Zip::File.open(zip_f.path) do |zf|
      dest_dir = FileUtils.mkdir_p(File.join(tmplt_root,
                                             distrib_local_path(version)))[0]
      zf.each do |entry|
        dest_file = File.join(dest_dir, entry.name.encode('UTF-8', 'cp866'))
        FileUtils.rm_r(dest_file) if File.exist?(dest_file)
        entry.extract(dest_file)
      end
    end
    dest_dir
  end

  def download_distrib(tmp_f, user, password, version)
    tmp_f.write(
      http.get(
        "#{AssUpdater::UPDATEREPO_BASE}#{remote_distrib_file(version)}",
        user,
        password
      )
    )
  end

  # Often {#update_history}[][:targets] containe incorrect version number
  #
  def exclude_unknown_version(a)
    a.map do |i|
      i if all_update_history_versions.index(AssUpdater::AssVersion.new(i))
    end.compact
  end

  def conf_distribs_local_path(tmplt_root)
    File.join(tmplt_root, *remote_distrib_file('0.0.0.0').split('/').shift(2))
  end

  def distrib_local_path(v)
    File.dirname(remote_distrib_file(v))
  end

  def remote_distrib_file(v)
    get_distrib_info(v)['file']
  end

  def get_distrib_info(v)
    return get_distrib_info min_update_history_version if v.to_s == '0.0.0.0'
    update_history['update'].each do |h|
      next if h['version'] != v.to_s
      h['target'] = [] << h['target'] if h['target'].is_a? String
      return h
    end
    fail AssUpdater::Error, "Unckown version number `#{v}'"
  end

  def self.parse_updateinfo_txt(text)
    text =~ /Version=([\d\.]*)(\s*)FromVersions=[;]?([\d\.\;]*)(\s*)UpdateDate=([\d\.]*)/im
    r = { version: Regexp.last_match(1),
          from_versions: [],
          update_date: Regexp.last_match(5)
    }
    r[:from_versions] = Regexp.last_match(3).split(';') if Regexp.last_match(3)
    r
  end

  def self.parse_updatehistory_xml(xml)
    p = Nori.new(parser: :rexml, strip_namespaces: true)
    r = p.parse(xml)['updateList']
    r['update'] = [] << r['update'] if r['update'].is_a? Hash
    r
  end

  def self.get_update_info_text(inst)
    inst.http.get("#{get_updateinfo_path(inst)}/#{UPDINFO_TXT}")
  end

  def self.get_update_history_text(inst)
    zip_f = Tempfile.new('upd11_zip')
    begin
      zip_f.write(inst.http.get("#{get_updateinfo_path(inst)}/#{UPD11_ZIP}"))
      zip_f.rewind
      xml = ''
      Zip::File.open(zip_f.path) do |zf|
        upd11_zip = zf.glob('v8cscdsc.xml').first
        unless upd11_zip
          fail AssUpdater::Error,
               "File `v8cscdsc.xml' not fount in zip `#{UPD11_ZIP}'"
        end
        xml = upd11_zip.get_input_stream.read
      end
    ensure
      zip_f.close
      zip_f.unlink
    end
    xml.force_encoding 'UTF-8'
  end

  def self.get_updateinfo_path(inst)
    "#{UPDATEINFO_BASE}/#{inst.conf_code_name}/"\
      "#{inst.conf_redaction}/#{inst.platform_version}/"
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
    r.sub('.', '')
  end
end
