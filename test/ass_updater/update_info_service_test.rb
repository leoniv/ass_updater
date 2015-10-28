require 'test_helper'

class UpdateInfoServiceTest < Minitest::Test
  include AssUpdaterFixt

  def test_raw
    @update_service = Class.new(AssUpdater::UpdateInfoService) do
                        def parse
                          "parsed data"
                        end
                      end.new(self)
    assert_equal "parsed data", @update_service.send(:raw)
  end

  def test_get_updateinfo_path
    @update_service = Class.new(AssUpdater::UpdateInfoService) do
                        def parse
                          "parsed data"
                        end
                      end.new(ass_updater_mock('ccn','cred','pl_ver'))
    assert_equal "#{AssUpdater::UPDATEINFO_BASE}/ccn/cred/pl_ver/",
      @update_service.send(:updateinfo_path)
  end

  def test_parse
    assert_raises(StandardError) {AssUpdater::UpdateInfoService.new(self).parse}
  end
end
