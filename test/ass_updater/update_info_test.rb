require 'test_helper'

class UpdateInfoTest < Minitest::Test
  include AssUpdaterFixt

  def setup
    init_fixt
    @update_info = AssUpdater::UpdateInfo.new(ass_updater_stub('HRM','30','83',self))
  end

  def test_const
    assert_equal 'UpdInfo.txt',
      AssUpdater::UpdateInfo::UPDINFO_TXT
  end

  def test_parse
    expected = { version: '3.0.23.148',
                 from_versions: %w(3.0.23.132 3.0.23.139 3.0.23.142 3.0.23.143),
                 update_date: '22.09.2015'}
    assert_equal expected, @update_info.send(:raw)
  end

  def test_version
    assert_instance_of AssUpdater::AssVersion, @update_info.version
    assert_equal "3.0.23.148", @update_info.version.to_s
  end

  def test_square_brackets
    assert_equal "22.09.2015", @update_info[:update_date]
  end
end
