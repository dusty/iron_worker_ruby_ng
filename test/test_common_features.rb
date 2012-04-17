require 'helpers'
require 'zip/zip'

class CommonFeaturesTest < IWNGTest

  def test_merge_file
    code = code_bundle('test') do
      merge_file('test', 'test/data/dir2')
      merge_worker('test/hello.rb')
    end

    inspect_zip(code) do |zip|
      assert zip.find_entry('test/data/dir2/test')
    end
  end

  def test_merge_dir_check
    assert_raise RuntimeError, "should check if merged dir exists" do
      code_bundle('test') do
        merge_dir('dir2', 'test/data')
      end
    end
  end

  def test_merge_dir
    code = code_bundle('test') do
      merge_dir('test/data/dir2', 'test/data')
      merge_worker('test/hello.rb')
    end

    inspect_zip(code) do |zip|
      assert zip.find_entry('test/data/dir2/test')
    end
  end

  def test_symlinks
    File.unlink 'test/data/dir1/dir2' if
      File.symlink? 'test/data/dir1/dir2'

    Dir.chdir('test/data/dir1') do
      File.symlink('../dir2', 'dir2')
    end

    code = code_bundle 'test_symlinks' do
      merge_dir('test/data/dir1', 'test/data')
      merge_dir('test/data/dir2', 'test/data')
      worker_code 'puts File.read("test/data/dir1/dir2/test")'
    end

    inspect_zip(code) do |zip|
      assert_equal '../dir2', zip.read('test/data/dir1/dir2')
    end

    client.codes_create(code)
    task_id = client.tasks_create('test_symlinks').id
    client.tasks_wait_for(task_id)
    log = client.tasks_log(task_id)

    assert_equal "test", log

    File.unlink 'test/data/dir1/dir2'
  end

end
