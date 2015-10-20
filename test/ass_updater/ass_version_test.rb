require 'test_helper'

class AssVersionTest < Minitest::Test
  def v_new(v)
    AssUpdater::AssVersion.new(v)
  end

  def test_array_sort
    given = AssUpdater::AssVersion.convert_array(%w(2.3.4.1 3.3.2.1 1.2.3.4))
    assert_equal AssUpdater::AssVersion
      .convert_array(%w(1.2.3.4 2.3.4.1 3.3.2.1)), given.sort
  end

  def test_convert_array
    assert AssUpdater::AssVersion.convert_array(['1.2.3.4', '4.5.6.7']) ==
      [AssUpdater::AssVersion.new('1.2.3.4'),
       AssUpdater::AssVersion.new('4.5.6.7')]
  end

  def test_zerro_version
    assert AssUpdater::AssVersion.zerro_version.zerro?
  end

  def test_initialize
    assert_raises(ArgumentError) { AssUpdater::AssVersion.new('blah') }
    assert_instance_of AssUpdater::AssVersion,
                       AssUpdater::AssVersion.new('1.2.3.4')
    assert_instance_of AssUpdater::AssVersion,
                       AssUpdater::AssVersion.new(
                         AssUpdater::AssVersion.new('1.2.3.4')
                       )
    assert AssUpdater::AssVersion.new.zerro?
  end

  def test_to_s
    assert_equal v_new('1.2.3.4').to_s, '1.2.3.4'
  end

  def test_to_a
    assert_equal v_new('1.23.45.67').to_a, [1, 23, 45, 67]
  end

  def test_comapry
    less = '1.2.2.7'
    more = '1.2.3.1'
    assert v_new(more) > v_new(less)
    assert v_new(more) >= v_new(less)
    assert v_new(less) < v_new(more)
    assert v_new(less) <= v_new(more)
    assert v_new(less) == v_new(less)
    assert v_new(more) >= v_new(more)
    assert v_new(more) <= v_new(more)
  end

  def test_distrib_path
    tmpl_root = 'ass_tmpl_root'
    vendor = '1c'
    conf_code_name = 'hrm'
    assert_equal(
      v_new('1.2.3.4').distrib_path(tmpl_root, vendor, conf_code_name),
      File.join(tmpl_root, vendor, conf_code_name, '1_2_3_4')
    )
  end

  def test_redaction
    assert_equal v_new('2.5.4.55').redaction, '2.5'
  end
end
