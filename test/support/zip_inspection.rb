# Checks on the zip *format*, not on the contents.
#
module ZipInspection

    def self.available?(command)
        @available ||= {}
        @available.fetch(command) do
            @available[command] = system("which", command, out: File::NULL, err: File::NULL)
        end
    end

    # unzip -t walks the whole archive and checks every CRC.
    #
    def assert_readable_by_unzip(path)
        skip "unzip is not installed" unless ZipInspection.available?("unzip")

        assert system("unzip", "-tqq", path, out: File::NULL, err: File::NULL),
            "#{File.basename(path)} does not survive `unzip -t`"
    end

    # Flag if we accidentally enable zip64. It should be fine to use it,
    # but we haven't needed it so enabling it should be given some thought.
    #
    def assert_not_zip64(path)
        skip "zipinfo is not installed" unless ZipInspection.available?("zipinfo")

        report = IO.popen([ "zipinfo", "-v", path ], &:read)
        versions = report.scan(/minimum software version required to extract:\s+([\d.]+)/)
            .flatten.map(&:to_f)

        assert versions.any?, "zipinfo found no entries in #{File.basename(path)}"
        assert versions.max < 4.5,
            "entries are marked Zip64 (version needed to extract: #{versions.max})"
    end

end
