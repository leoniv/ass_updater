require 'test_helper'
require 'minitest/mock'

class AssUpdaterTest < Minitest::Test

  def upd_mock(http=nil)
    mock = Minitest::Mock.new
    mock.expect(:conf_code_name,"ccn")
    mock.expect(:conf_redaction,"cred")
    mock.expect(:platform_version,"pl_ver")
    mock.expect(:http,http)
    mock
  end

  def setup
    @fixtures = File.expand_path("../fixtures",__FILE__)
    @fixt_updinfo_txt = File.join(@fixtures,"UpdInfo.txt")
    @fixt_v8upd11_zip = File.join(@fixtures,"v8upd11.zip")
    @fixt_v8upd11_xml = File.join(@fixtures,"v8upd11.xml")
    @fixt_tmplt_root = File.join(@fixtures,"tmplts")
    @fixt_distribs_root = File.join(@fixtures,"distribs")
    @tmp_tmplt_root = Dir.mktmpdir("tmplt_root")
    @_1cv8zip_content = ["1cv8.cfu", "1cv8.mft", "1cv8upd.htm", "UpdInfo.txt", "Зарплата и Управление Персоналом. Версия 3.0.11. Новое в версии.htm"]
    AssUpdater.send(:public_class_method, *AssUpdater.private_methods)
  end

   def get(uri,*args)
    case uri
     when /.*UpdInfo\.txt/i
       File.new(@fixt_updinfo_txt).read
     when /.*v8upd11\.zip/i
       File.read(@fixt_v8upd11_zip)
     when /#{AssUpdater::UPDATEREPO_BASE}(.*\.zip)/i
       File.read File.join(@fixt_distribs_root,$1)
     else
       raise "Unckown uri #{uri}"
    end
  end

  def teardown
    FileUtils.remove_entry @tmp_tmplt_root
  end

  def updater
    AssUpdater.new("HRM","3.0") do |n|
      n.http = self
    end
  end

  def test_constants
    assert_equal AssUpdater::PLATFORM_VERSIONS ,{:"8.2"=>"82",:"8.3"=>"83"}
    assert_equal AssUpdater::UPDATEREPO_BASE , "http://downloads.v8.1c.ru/tmplts/"
    assert_equal AssUpdater::UPDATEINFO_BASE , "http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/"
    assert_equal AssUpdater::UPDINFO_TXT , "UpdInfo.txt"
    assert_equal AssUpdater::UPD11_ZIP  , "v8upd11.zip"
    assert_equal AssUpdater::KNOWN_CONF_CODENAME , {HRM:"Зарплата и управление персоналом",
                        Accounting:"Бухгалтерия предприятия",
                        AccountingKz:"Бухгалтерия для Казахстана"}
  end

  def ar_v(a)
    AssUpdater::AssVersion.convert_array(a)
  end

  def test_required_distrib_for_update
    assert_equal updater.required_distrib_for_update("3.0.8.46","3.0.14.17") ,
      ar_v(["3.0.14.17","3.0.13.38","3.0.12.40","3.0.11.41","3.0.11.39","3.0.10.33"] ),
      "Потребные обновления с версии 3.0.8.46 до версии 3.0.14.17"
    assert_equal updater.required_distrib_for_update("3.0.23.120") ,
      ar_v(["3.0.23.148","3.0.23.139"] ),
      "Потребные обновления с версии 3.0.23.139 до текущей"
    assert_equal updater.required_distrib_for_update(nil,"3.0.11.39") ,
      ar_v(["3.0.11.39","3.0.10.33","3.0.9.28","3.0.8.46"] ),
      "Потребные обновления с 0 версии до версии 3.0.11.39"
    assert_raises (AssUpdater::Error) {updater.required_distrib_for_update("12.2.3.4","13.0.0.1")}
      #"Не известные версии вызывает исключение"
    assert_raises (AssUpdater::Error) {updater.required_distrib_for_update("0.0.0.2","0.0.0.1")}
      #"Попытка с болшей версии на меньшую"
   end

  def test_remote_distrib_file
    assert updater.send(:remote_distrib_file,"3.0.10.33") == "1c/HRM/3_0_10_33/1cv8.zip"
    assert_raises ( AssUpdater::Error ) {updater.send(:remote_distrib_file, "0.0.0.0")}
  end

  def test_distrib_local_path
    assert_equal  "1c/HRM/3_0_10_33",updater.send(:distrib_local_path,"3.0.10.33")
  end

  def ass_version(v)
    AssUpdater::AssVersion.new(v)
  end

  def test_known_local_distribs
    assert_equal updater.known_local_distribs(@fixt_tmplt_root) , ar_v( ["1.1.1.1","2.2.2.2","3.3.3.3"] )
  end

  def test_get_distrib
    updater.get_distrib("","","3.0.8.46",@tmp_tmplt_root)
    assert_equal Dir.glob(File.join(@tmp_tmplt_root,"1c","HRM","3_0_8_46")) , @_1cv8zip_content
  end

  def test_get_distribs
    updater.get_distribs("","",ar_v(["3.0.9.28","3.0.10.33"]),@tmp_tmplt_root)
    assert_equal Dir.glob(File.join(@tmp_tmplt_root,"1c","HRM","3_0_9_28")) , @_1cv8zip_content
    assert_equal Dir.glob(File.join(@tmp_tmplt_root,"1c","HRM","3_0_10_33")) , @_1cv8zip_content
  end

  def test_curent_version
    assert updater.curent_vesrsion == "3.0.23.148"
  end

  def test_that_it_has_a_version_number
    refute_nil ::AssUpdater::VERSION
  end

  def test_valid_platform_version
    assert "82" == AssUpdater.valid_platform_version("8.2")
    assert "83" == AssUpdater.valid_platform_version("8.3")
    assert_raises(AssUpdater::Error) {AssUpdater.valid_platform_version "blah"}
  end

  def test_valid_redaction
    assert "30" == AssUpdater.valid_redaction("3.0")
    assert_raises(AssUpdater::Error){AssUpdater.valid_redaction("blah")}
  end

  def test_const_updateinfo_base
    assert AssUpdater::UPDATEINFO_BASE == "http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/"
  end

  def test_get_updateinfo_path
   assert AssUpdater.get_updateinfo_path(upd_mock) == "#{AssUpdater::UPDATEINFO_BASE}/ccn/cred/pl_ver/"
  end

  def test_get_update_info_text
    http = Minitest::Mock.new
    http.expect(:get,File.new(@fixt_updinfo_txt).read,["#{AssUpdater.get_updateinfo_path(upd_mock)}/#{AssUpdater::UPDINFO_TXT}"])
    inst = upd_mock(http)
    assert File.new(@fixt_updinfo_txt).read == AssUpdater.get_update_info_text(inst)
  end

  def test_get_update_history_text
    http = Minitest::Mock.new
    http.expect(:get,File.new(@fixt_v8upd11_zip).read,["#{AssUpdater.get_updateinfo_path(upd_mock)}/#{AssUpdater::UPD11_ZIP}"])
    inst = upd_mock(http)
    ht = AssUpdater.get_update_history_text(inst)
    assert File.new(@fixt_v8upd11_xml).read == ht
  end

  def test_parse_updateinfo_txt
   assert AssUpdater.parse_updateinfo_txt(File.new(@fixt_updinfo_txt).read) == {version:"3.0.23.148",from_versions:%w{3.0.23.132 3.0.23.139 3.0.23.142 3.0.23.143},update_date:"22.09.2015"}
  end

  def test_parse_updatehistory_xml
    up_h = AssUpdater.parse_updatehistory_xml(File.read(@fixt_v8upd11_xml))
    assert_instance_of Hash, up_h
    assert ! up_h.has_key?("updateList")
    assert up_h.has_key? "update"
  end

  def test_ass_version
    assert_instance_of AssUpdater::AssVersion, AssUpdater.ass_version("2.0.1.1")
    assert_instance_of AssUpdater::AssVersion, AssUpdater.ass_version(AssUpdater::AssVersion.new("2.0.1.1"))
  end
end
