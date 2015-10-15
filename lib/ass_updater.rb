require "zip"
require "nori"
require "ass_updater/version"

class AssUpdater

  class Error < StandardError; end
  class Runtime < AssUpdater::Error; end
  class HTTP ;end
  class AssVersion ;end

  require "ass_updater/ass_version"
  require "ass_updater/http"

  PLATFORM_VERSIONS = {:"8.2"=>"82",:"8.3"=>"83"}
  KNOWN_CONF_CODENAME = {HRM:"Зарплата и управление персоналом",
                        Accounting:"Бухгалтерия предприятия",
                        AccountingKz:"Бухгалтерия для Казахстана"}
  UPDATEREPO_BASE = "http://downloads.v8.1c.ru/tmplts/"
  UPDATEINFO_BASE = "http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/"
  UPDINFO_TXT = "UpdInfo.txt"
  UPD11_ZIP   = "v8upd11.zip"

  attr_reader :conf_code_name,:conf_redaction,:platform_version,:update_info
  attr_accessor :http

  #FIXME require doc
  def initialize(conf_code_name,conf_redaction,platform_version=PLATFORM_VERSIONS.keys.last)
    @conf_code_name = conf_code_name
    @http = AssUpdater::HTTP.new
    @conf_redaction = AssUpdater.valid_redaction(conf_redaction)
    @platform_version = AssUpdater.valid_platform_version(platform_version)
    if block_given?
      yield self
    end
  end

  def curent_vesrsion
    update_info[:version]
  end

  def update_info
    @update_info ||= AssUpdater.parse_updateinfo_txt(AssUpdater.get_update_info_text(self))
    @update_info
  end

  def update_history
    @update_history ||= AssUpdater.parse_updatehistory_xml(AssUpdater.get_update_history_text(self))
    @update_history
  end

  def required_distrib_for_update(from_ver,to_ver)
    from_ver ||= AssUpdater::AssVersion.zerro_version
    to_ver ||= AssUpdater::AssVersion.new(curent_vesrsion)
    if AssUpdater::AssVersion.new(from_versions) >= AssUpdater::AssVersion.new(to_ver)
      []
    end
raise "FIXME"
  end

  #FIXME require doc
  #Загружает и распаковывает дистрибутив новления в tmpl_root
  def get_distrib(user,password,version,tmplt_root)
    zip_f = Tempfile.new("1cv8_zip")
    begin
      zip_f.write(http.get("#{AssUpdater::UPDATEREPO_BASE}#{remote_distrib_file(version)}",user,password))
      zip_f.rewind
      Zip::File.open(zip_f.path) do |zf|
        dest_dir = FileUtils.mkdir_p(File.join(tmplt_root,distrib_local_path(version)))[0]
        zf.each do |entry|
          dest_file = File.join(dest_dir,entry.name.encode("UTF-8","cp866"))
          FileUtils.rm_r(dest_file) if File.exist?(dest_file)
          entry.extract(dest_file)
        end
      end
    ensure
      zip_f.close
      zip_f.unlink
    end
  end

  def get_distribs(user,password,versions,tmplt_root)
    versions.each do |version|
      get_distrib(user,password,version,tmplt_root)
    end
  end

  def known_local_distribs(tmplt_root)
    (Dir.entries(conf_distribs_local_path(tmplt_root)).map do |e|
      if e != "." && e != ".."
        begin
          AssUpdater::AssVersion.new(e.split("_").join("."))
        rescue ArgumentError
          nil
        end
      end
    end).compact
  end

  def http
    @http
  end

 private

  def conf_distribs_local_path(tmplt_root)
    File.join(tmplt_root,*remote_distrib_file(0).split("/").shift(2))
  end

  def distrib_local_path(v)
    File.dirname(remote_distrib_file(v))
  end

  def remote_distrib_file(v)
    get_distrib_info(v)["file"]
  end

  def get_distrib_info(v)
    update_history["update"].each do |h|
      if h["version"] == v.to_s || v.to_s == "0"
        return h
      end
    end
    raise AssUpdater::Error.new "Unckown version number `#{v}'"
  end

  def self.parse_updateinfo_txt(text)
    text =~ /Version=([\d\.]*)(\s*)FromVersions=[;]?([\d\.\;]*)(\s*)UpdateDate=([\d\.]*)/im
    {version:$1,from_versions:$3.split(";"),update_date:$5}
  end

  def self.parse_updatehistory_xml(xml)
    p =  Nori.new(:parser => :rexml, :strip_namespaces=>true)
    p.parse(xml)["updateList"]
  end

  def self.get_update_info_text(inst)
    inst.http.get("#{get_updateinfo_path(inst)}/#{UPDINFO_TXT}")
  end

  def self.get_update_history_text(inst)
    zip_f = Tempfile.new("upd11_zip")
    begin
      zip_f.write(inst.http.get("#{get_updateinfo_path(inst)}/#{UPD11_ZIP}"))
      zip_f.rewind
      xml= ""
      Zip::File.open(zip_f.path) do |zf|
        upd11_zip = zf.glob("v8cscdsc.xml").first
        raise AssUpdater::Error.new "File `v8cscdsc.xml' not fount in zip `#{UPD11_ZIP}'" unless upd11_zip
        xml = upd11_zip.get_input_stream.read
      end
    ensure
      zip_f.close
      zip_f.unlink
    end
    xml.force_encoding "UTF-8"
  end

  def self.get_updateinfo_path(inst)
    "#{UPDATEINFO_BASE}/#{inst.conf_code_name}/#{inst.conf_redaction}/#{inst.platform_version}/"
  end

  def self.valid_platform_version(v)
    raise AssUpdater::Error.new "Invalid platform_version `#{v}'. Support #{PLATFORM_VERSIONS.keys.join(" | ")} versions only." unless PLATFORM_VERSIONS.has_key?(v.to_sym)
    PLATFORM_VERSIONS[v.to_sym]
  end

  def self.valid_redaction(r)
    raise AssUpdater::Error.new "Invalid redaction #{r}" unless r =~ /\d\.\d/
    r.sub(".","")
  end

end
