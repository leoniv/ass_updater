require 'test_helper'

class UpdateDistribTest < Minitest::Test
  include AssUpdaterFixt

  def setup
    init_fixt
    @version_info = {'vendor' => 'Фирма "1С"',
                     'file' => '1c/HRM/3_0_10_32/1cv8.zip',
                     'size' => '23 014 788',
                     'version' => '3.0.10.32',
                     'target' => ['3.0.9.28'],
                     '@configuration'=>'ЗарплатаИУправлениеПерсоналом'
                     }
    @_1cv8zip_content = ['1cv8.cfu',
                         '1cv8.mft',
                         '1cv8upd.htm',
                         'UpdInfo.txt',
                         'Зарплата и Управление Персоналом.'\
                         ' Версия 3.0.11. Новое в версии.htm']
    @tmp_tmplt_root = Dir.mktmpdir('tmplt_root')
    @update_distrib = AssUpdater::UpdateDistrib.new('3.0.10.32',@tmp_tmplt_root,ass_updater_stub('HRM','30','83',self,@version_info))
  end

  def teardown
    FileUtils.remove_entry @tmp_tmplt_root
  end

  def test_local_path
    assert_equal File.join(@tmp_tmplt_root,
                            '1c/HRM/3_0_10_32'),
                 @update_distrib.local_path
  end

  def test_file
    assert_equal File.join(AssUpdater::UPDATEREPO_BASE,
                           '1c/HRM/3_0_10_32/1cv8.zip'),
                 @update_distrib.file
  end

  def test_get
    assert_equal @update_distrib,
      @update_distrib.get('', '')
    assert_equal @_1cv8zip_content.sort,
      Dir.glob(File.join(@tmp_tmplt_root,
                         '1c',
                         'HRM',
                         '3_0_10_32',
                         '*')).map{|i| File.basename(i).force_encoding('UTF-8')}.sort
  end

  def test_file_list
    @update_distrib.get('', '')
    expected = Dir.glob(File.join(@tmp_tmplt_root,
                         '1c',
                         'HRM',
                         '3_0_10_32',
                         '*')).map{|i| i.force_encoding('UTF-8')}
    assert_equal expected, @update_distrib.file_list

    expected = Dir.glob(File.join(@tmp_tmplt_root,
                         '1c',
                         'HRM',
                         '3_0_10_32',
                         '*.html')).map{|i| i.force_encoding('UTF-8')}
    assert_equal expected, @update_distrib.file_list('*.html')
  end

  def test_tmplt_root
    assert_equal @tmp_tmplt_root, @update_distrib.tmplt_root
  end

  def test_version
    assert_equal '3.0.10.32', @update_distrib.version.to_s
  end

  def test_version_info
    assert_equal @version_info, @update_distrib.version_info
  end

  def test_target
    assert_equal AssUpdater::AssVersion.convert_array(['3.0.9.28']),
      @update_distrib.target
  end

  def test_fix_path
    path = '1c\\Accounting\\2_0_15_8\\1cv8.zip'
    fix_path = '1c/Accounting/2_0_15_8/1cv8.zip'
    assert_equal fix_path, @update_distrib.send(:fix_path, path)
  end

  def test_encode_utf_8
    assert_equal 'UTF-8', @update_distrib.send(:encode_, 'UTF-8')
    assert_equal 'УТФ-8', @update_distrib.send(:encode_, 'УТФ-8')
  end

  def test_encode_cp_1251
    assert_equal 'ВИН-1251', @update_distrib.send(:encode_, 'ВИН-1251'.encode('cp1251', 'UTF-8'))
  end

  def test_encode_cp_866
    assert_equal 'ВИН-866', @update_distrib.send(:encode_, 'ВИН-866'.encode('cp866', 'UTF-8'))
  end
end
