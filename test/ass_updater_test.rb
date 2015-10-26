require 'test_helper'
require 'minitest/mock'

class AssUpdaterTest < Minitest::Test
  include AssUpdaterFixt

  def setup
    init_fixt
    @tmp_tmplt_root = Dir.mktmpdir('tmplt_root')
    AssUpdater.send(:public_class_method, *AssUpdater.private_methods)
  end

  def teardown
    FileUtils.remove_entry @tmp_tmplt_root
  end

  def updater
    AssUpdater.new('HRM', '3.0') do |n|
      n.http = self
    end
  end

  def test_constants
    assert_equal AssUpdater::PLATFORM_VERSIONS, {:"8.2"=>'82', :"8.3"=>'83'}
    assert_equal AssUpdater::UPDATEREPO_BASE , 'http://downloads.v8.1c.ru/tmplts/'
    assert_equal AssUpdater::UPDATEINFO_BASE , 'http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/'
    assert_equal AssUpdater::UPD11_ZIP  , 'v8upd11.zip'
    assert_equal AssUpdater::KNOWN_CONF_CODENAME , {HRM:'Зарплата и управление персоналом',
                        Accounting:'Бухгалтерия предприятия',
                        AccountingKz:'Бухгалтерия для Казахстана'}
  end

  def ar_v(a)
    AssUpdater::AssVersion.convert_array(a)
  end

  def test_required_distrib_for_update
    assert_equal updater.required_distrib_for_update('3.0.8.46', '3.0.14.17') ,
      ar_v(['3.0.14.17', '3.0.13.38', '3.0.12.38', '3.0.11.41', '3.0.11.36', '3.0.10.32', '3.0.9.28'] ),
      'Потребные обновления с версии 3.0.8.46 до версии 3.0.14.17'
    assert_equal updater.required_distrib_for_update('3.0.23.120') ,
      ar_v(['3.0.23.148', '3.0.23.132'] ),
      'Потребные обновления с версии 3.0.23.120 до текущей'
    assert_equal updater.required_distrib_for_update(nil, '3.0.11.39') ,
      ar_v(['3.0.11.39', '3.0.10.32', '3.0.9.28', '3.0.8.46'] ),
      'Потребные обновления с 0 версии до версии 3.0.11.39'
    assert_raises (AssUpdater::Error) {updater.required_distrib_for_update('12.2.3.4', '13.0.0.1')}
      #'Не известные версии вызывает исключение'
    assert_raises (ArgumentError) {updater.required_distrib_for_update('0.0.0.2', '0.0.0.1')}
      #'Попытка с болшей версии на меньшую'
   end

  def test_remote_distrib_file
    assert updater.send(:remote_distrib_file, '3.0.10.33') == '1c/HRM/3_0_10_33/1cv8.zip'
    assert_raises ( AssUpdater::Error ) {updater.send(:remote_distrib_file, '0.1.0.0')}
  end

  def test_distrib_local_path
    assert_equal  '1c/HRM/3_0_10_33', updater.send(:distrib_local_path, '3.0.10.33')
  end

  def test_known_local_distribs
    assert_equal updater.known_local_distribs(@fixt_tmplt_root) , ar_v( ['1.1.1.1', '2.2.2.2', '3.3.3.3'] )
  end

  def test_get_distrib
    assert_equal File.join(@tmp_tmplt_root,'1c/HRM/3_0_8_46'), updater.get_distrib('', '', '3.0.8.46', @tmp_tmplt_root)
    assert_equal @_1cv8zip_content, Dir.glob(File.join(@tmp_tmplt_root, '1c', 'HRM', '3_0_8_46', '*')).map{|i| File.basename(i).force_encoding('UTF-8')}
    assert_equal @_1cv8zip_content, Dir.glob(File.join(@tmp_tmplt_root, '1c', 'HRM', '3_0_8_46', '*')).map{|i| File.basename(i).force_encoding('UTF-8')}
  end

  def test_get_distribs
    expected = [File.join(@tmp_tmplt_root,'1c/HRM/3_0_9_28'),
                File.join(@tmp_tmplt_root,'1c/HRM/3_0_10_33')]
    assert_equal expected, updater.get_distribs('', '', ar_v(['3.0.9.28', '3.0.10.33']), @tmp_tmplt_root)
    assert_equal @_1cv8zip_content, Dir.glob(File.join(@tmp_tmplt_root, '1c', 'HRM', '3_0_9_28', '*')).map{|i| File.basename(i).force_encoding('UTF-8')}
    assert_equal @_1cv8zip_content, Dir.glob(File.join(@tmp_tmplt_root, '1c', 'HRM', '3_0_10_33', '*')).map{|i| File.basename(i).force_encoding('UTF-8')}
  end

  def test_that_it_has_a_version_number
    refute_nil ::AssUpdater::VERSION
  end

  def test_valid_platform_version
    assert '82' == AssUpdater.valid_platform_version('8.2')
    assert '83' == AssUpdater.valid_platform_version('8.3')
    assert_raises(AssUpdater::Error) {AssUpdater.valid_platform_version 'blah'}
  end

  def test_valid_redaction
    assert '30' == AssUpdater.valid_redaction('3.0')
    assert_raises(AssUpdater::Error){AssUpdater.valid_redaction('blah')}
  end

  def test_const_updateinfo_base
    assert AssUpdater::UPDATEINFO_BASE == 'http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/'
  end

end
