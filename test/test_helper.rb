if ENV["SIMPLECOV"] then
  require "simplecov"
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ass_updater'

require 'minitest/autorun'
require 'pry'

module AssUpdaterFixt

  def ass_updater_mock(conf_code_name,conf_redaction,platform_version,http=nil)
    mock = Minitest::Mock.new
    mock.expect(:conf_code_name, conf_code_name)
    mock.expect(:conf_redaction, conf_redaction)
    mock.expect(:platform_version, platform_version)
    mock.expect(:http, http)
    mock
  end

  def ass_updater_stub(conf_code_name,conf_redaction,platform_version,http=nil,version_info={})
    AssUpdaterStab.new(conf_code_name,conf_redaction,platform_version,http,version_info)
  end

  def init_fixt
    @fixtures = File.expand_path('../fixtures', __FILE__)
    @fixt_updinfo_txt = File.join(@fixtures, 'UpdInfo.txt')
    @fixt_v8upd11_zip = File.join(@fixtures, 'v8upd11.zip')
    @fixt_v8upd11_xml = File.join(@fixtures, 'v8upd11.xml')
    @fixt_tmplt_root = File.join(@fixtures, 'tmplts')
    @fixt_distribs_root = File.join(@fixtures, 'distribs')
  end

  def get(uri, *args)
    case uri
     when /.*UpdInfo\.txt/i
       File.new(@fixt_updinfo_txt).read
     when /.*v8upd11\.zip/i
       File.read(@fixt_v8upd11_zip)
     when /#{AssUpdater::UPDATEREPO_BASE}(.*\.zip)/i
       File.read File.join(@fixt_distribs_root, $1)
     else
       raise "Unckown uri #{uri}"
    end
  end
end

class AssUpdaterStab
  class UpdateHistoryStub
    def initialize(version_info)
      @version_info = version_info
    end
    def [](*args)
      @version_info
    end
  end
  def initialize(conf_code_name, conf_redaction, platform_version, http, version_info={})
    @http = http
    @conf_code_name = conf_code_name
    @conf_redaction = conf_redaction
    @platform_version = platform_version
    @update_history = AssUpdaterStab::UpdateHistoryStub.new(version_info)
  end

  def update_history
    @update_history
  end

  def http
    @http
  end

  def conf_code_name
    @conf_code_name
  end

  def conf_redaction
    @conf_redaction
  end

  def platform_version
    @platform_version
  end
end
