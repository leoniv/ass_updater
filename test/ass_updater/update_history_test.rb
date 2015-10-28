require 'test_helper'

class UpdateHistryTest < Minitest::Test
  include AssUpdaterFixt

  def setup
    init_fixt
    @update_history = AssUpdater::UpdateHistory.new(ass_updater_stub('HRM','30','83',self))
    @fixt_zerro_zip = File.join(@fixtures,'zerro.zip')
  end

  def test_parse
    up_h = @update_history.send(:parse)
    assert_instance_of Hash, up_h
    assert ! up_h.key?('updateList')
    assert up_h.key? 'update'
  end

  def test_unzip_fail
    assert_raises(AssUpdater::Error) { @update_history.send(:unzip, File.new(@fixt_zerro_zip)) }
  end

  def test_get
    assert_equal File.new(@fixt_v8upd11_xml).read,
      @update_history.send(:get)
  end

  def test_min_version
    assert_equal '3.0.8.46', @update_history.min_version.to_s
  end

  def test_max_version
    assert_equal '3.0.23.148', @update_history.max_version.to_s
  end

  def test_all_version
    actual = @update_history.all_versions
    assert_equal 54, actual.size
    assert_equal '3.0.9.28', actual.sort[1].to_s
  end

  def test_target
    actual = AssUpdater::AssVersion.convert_array(['3.0.9.28']),
      @update_history.target('3.0.10.32')
  end

  def test_square_brackets
    expected = {'vendor' => 'Фирма "1С"',
                'file' => '1c/HRM/3_0_10_32/1cv8.zip',
                'size' => '23 014 788',
                'version' => '3.0.10.32',
                'target' => ['3.0.9.28'],
                '@configuration'=>'ЗарплатаИУправлениеПерсоналом'
               }
    assert_equal expected, @update_history['3.0.10.32']
    assert_raises(AssUpdater::Error) { @update_history['1.2.3.4'] }
  end

end
