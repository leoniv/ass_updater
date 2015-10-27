#-- incoding utf-8


class AssUpdater
  #
  # Handle fo updtade history from v8upd11.xml
  # @note (see AssUpdater::UpdateInfoService)
  #
  class UpdateHistory < AssUpdater::UpdateInfoService

    # Returm min distrib version from update history
    # @return [AssUpdater::AssVersion]
    def min_version
      all_versions.min
    end

    # Return max version from update histry
    # @return [AssUpdater::AssVersion]
    def max_version
      all_versions.max
    end

    # Return all versions found in histry
    # @return [Array<AssUpdater::AssVersion>]
    def all_versions
      r = []
      raw['update'].each do |h|
        r << h['version']
      end
      AssUpdater::AssVersion.convert_array r
    end

    # Return info about version <version>
    # @param version [String,AssUpdater::AssVersion]
    # @return [Hash]
    # @raise [AssUpdater::Error] if info for version not found
    def [](version)
      return [min_version] if version.to_s == '0.0.0.0'
      raw['update'].each do |h|
        next if h['version'] != version.to_s
        h['target'] = [] << h['target'] if h['target'].is_a? String
        return h
      end
      fail AssUpdater::Error, "Unkown version number `#{version}'"
    end

    # Return array of target versions for update to version <version>
    # @param version [String,AssUpdater::AssVersion]
    # @return [Array<AssUpdater::AssVersion>]
    # @note (see #ex
    def target(version)
      exclude_unknown_version(
        AssUpdater::AssVersion.convert_array self[version]['target']
      )
    end


  private

    # @note Often ['target'] containe incorrect version number
    #  not fonded in {#all_versions}.
    #
    def exclude_unknown_version(a)
      a.map do |i|
        i if all_versions.index(i)
      end.compact
    end

    def parse
      r = Nori.new(parser: :rexml,
                   strip_namespaces: true).parse(get)['updateList']
      r['update'] = [] << r['update'] if r['update'].is_a? Hash
      r
    end

    def get
      zip_f = Tempfile.new('upd11_zip')
      begin
        zip_f.write(ass_updater.http.get("#{updateinfo_path}/#{UPD11_ZIP}"))
        zip_f.rewind
        xml = ''
        Zip::File.open(zip_f.path) do |zf|
          upd11_zip = zf.glob('v8cscdsc.xml').first
          unless upd11_zip
            fail AssUpdater::Error,
                 "File `v8cscdsc.xml' not fount in zip `#{UPD11_ZIP}'"
          end
          xml = upd11_zip.get_input_stream.read
        end
      ensure
        zip_f.close
        zip_f.unlink
      end
      xml.force_encoding 'UTF-8'
    end
  end
end
