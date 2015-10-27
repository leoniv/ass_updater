require 'test_helper'
require 'minitest/mock'

class AssUpdaterTest < Minitest::Test
  include AssUpdaterFixt

  def setup
    init_fixt
    AssUpdater.send(:public_class_method, *AssUpdater.private_methods)
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

  def test_update_info
    assert_instance_of AssUpdater::UpdateInfo, updater.update_info
  end

  def test_required_versions_for_update
    assert_equal updater.required_versions_for_update('3.0.8.46', '3.0.14.17') ,
      ar_v(['3.0.14.17', '3.0.13.38', '3.0.12.38', '3.0.11.41', '3.0.11.36', '3.0.10.32', '3.0.9.28'] ),
      'Потребные обновления с версии 3.0.8.46 до версии 3.0.14.17'
    assert_equal updater.required_versions_for_update('3.0.23.120') ,
      ar_v(['3.0.23.148', '3.0.23.132'] ),
      'Потребные обновления с версии 3.0.23.120 до текущей'
    assert_equal updater.required_versions_for_update(nil, '3.0.11.39') ,
      ar_v(['3.0.11.39', '3.0.10.32', '3.0.9.28', '3.0.8.46'] ),
      'Потребные обновления с 0 версии до версии 3.0.11.39'
    assert_raises (AssUpdater::Error) {updater.required_versions_for_update('12.2.3.4', '13.0.0.1')}
      #'Не известные версии вызывает исключение'
    assert_raises (ArgumentError) {updater.required_versions_for_update('0.0.0.2', '0.0.0.1')}
      #'Попытка с болшей версии на меньшую'
   end

  def test_known_local_distribs
    assert_equal updater.known_local_distribs(@fixt_tmplt_root) , ar_v( ['1.1.1.1', '2.2.2.2', '3.3.3.3'] )
  end

  def test_new_update_distrib
    assert_instance_of AssUpdater::UpdateDistrib, updater.send(:new_update_distrib, '3.0.8.46',@tmp_tmplt_root)
  end

  def get_update_mocked_updater
    Class.new(AssUpdater) do
      def initialize
      end

      def new_update_distrib(version, tmplt_root)
        @mock = Minitest::Mock.new
        @mock.expect(:get, @mock, ['user', 'password'])
        @mock.expect(:version, version)
        @mock.expect(:tmplt_root, tmplt_root)
      end
    end.new
  end

  def test_get_update
    updater = get_update_mocked_updater
    mock = updater.get_update('user', 'password', '3.0.8.46', @tmp_tmplt_root)
    assert_equal '3.0.8.46', mock.version
    assert_equal @tmp_tmplt_root, mock.tmplt_root
    mock.verify
  end

  def test_get_updates
    updater = get_update_mocked_updater
    versions = ar_v(['3.0.9.28', '3.0.10.33'])
    block_colled = 0
    mocks = updater.get_updates('user',
                                'password',
                                versions ,
                                @tmp_tmplt_root) do |mock|
      block_colled += 1
      assert_equal versions[block_colled-1], mock.version
      assert_equal @tmp_tmplt_root, mock.tmplt_root
      mock.verify
    end
    assert_equal 2, block_colled
    assert_equal 2, mocks.size
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
