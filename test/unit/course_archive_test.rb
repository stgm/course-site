require 'test_helper'
require_relative '../support/zip_inspection'

class CourseArchiveTest < ActiveSupport::TestCase

    include ZipInspection

    def entries(path)
        Zip::File.open(path) { |zip| zip.to_h { |e| [ e.name, e.get_input_stream.read ] } }
    end

    test "replaces a failed entry with an error note and keeps writing" do
        archive = CourseArchive.new

        file = ZipWriter.to_tempfile(basename: "archive-test") do |zip|
            archive.send(:add_entry, zip, "broken.pdf") { raise "boom" }
            archive.send(:add_entry, zip, "fine.txt") { |io| io.write("still here") }
        end

        written = entries(file.path)
        assert_equal [ "broken.pdf.ERROR.txt", "fine.txt" ], written.keys.sort
        assert_includes written["broken.pdf.ERROR.txt"], "Could not generate broken.pdf"
        assert_equal "still here", written["fine.txt"],
            "an entry after a failed one must still be written"

        assert_readable_by_unzip(file.path)
        assert_not_zip64(file.path)
    ensure
        file&.close!
    end

    test "builds a readable archive" do
        file = CourseArchive.new.to_tempfile

        assert_includes entries(file.path).keys, "grades.xlsx"
        assert_readable_by_unzip(file.path)
        assert_not_zip64(file.path)
    ensure
        file&.close!
    end

end
