#-- encoding utf-8

class AssUpdater
  # Implement work with distributives of configuration update
  class UpdateDistrib
    attr_reader :ass_updater, :version_info, :version, :target, :tmplt_root

    # @param ass_updater [AssUpdater] owner object
    # @param version [String AssUpdater::AssVersion]
    # @param tmplt_root [String] path to 1C update templates
    def initialize(version, tmplt_root, ass_updater)
      @ass_updater = ass_updater
      @version = AssUpdater::AssVersion.new(version)
      @version_info = @ass_updater.update_history[@version]
      @tmplt_root = tmplt_root.to_s.force_encoding('UTF-8')
      @target = AssUpdater::AssVersion.convert_array version_info['target']
    end

    # Download <version> distributive of configuration update and uzip into
    # tmplt_root. Exists in template_root distrib will be overwritten.
    # @note Require authorization.
    # @note Service http://downloads.v8.1c.ru
    #  often unavailable and it fail on timeout. Don't worry and try again.
    # @param user [String] authorization user name
    # @param password [String] authorization password
    # @return [AssUpdater::UpdateDistrib] self
    def get(user, password)
      zip_f = Tempfile.new('1cv8_zip')
      begin
        download_distrib(zip_f, user, password)
        zip_f.rewind
        unzip_all(zip_f)
      ensure
        zip_f.close
        zip_f.unlink
      end
      self
    end

    # Return path to distributive zip file on http server
    def file
      File.join(AssUpdater::UPDATEREPO_BASE, fix_path(version_info_file))
    end

    # Return local path where distributive installed
    def local_path
      File.join(tmplt_root, File.dirname(version_info_file))
    end

    # Return files included in distributive. Files find in {#local_path}
    # @param pattern (see Dir::glob)
    def file_list(pattern = '*')
      Dir.glob(File.join(local_path, pattern)).map do |f|
        f.force_encoding 'UTF-8'
      end
    end

    private

    def version_info_file
      fix_path version_info['file']
    end

    def fix_path(path)
      path.tr '\\', '/'
    end

    def unzip_all(zip_f)
      Zip::File.open(zip_f.path) do |zf|
        zf.each do |entry|
          dest_file = File.join(local_path, encode_(entry.name))
          FileUtils.mkdir_p(File.dirname(dest_file))
          FileUtils.rm_r(dest_file) if File.exist?(dest_file)
          entry.extract(dest_file)
        end
      end
      local_path
    end

    require 'rchardet'

    def encode_(str)
      en = CharDet.detect(str)["encoding"]
      str.encode('UTF-8', en)
    end
    private :encode_

    def download_distrib(tmp_f, user, password)
      tmp_f.write(ass_updater.http.get(file,
                                       user,
                                       password
                                      )
                 )
    end
  end
end
