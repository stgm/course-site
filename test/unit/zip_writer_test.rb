require 'test_helper'

class ZipWriterTest < ActiveSupport::TestCase

    def entries(path)
        Zip::File.open(path) { |zip| zip.to_h { |e| [ e.name, e.get_input_stream.read ] } }
    end

    test "builds a zip on disk and returns a readable tempfile" do
        file = ZipWriter.to_tempfile(basename: "test") do |zip|
            ZipWriter.add_stream(zip, "a.txt", StringIO.new("hello"))
            ZipWriter.add_stream(zip, "dir/b.txt", StringIO.new("world"))
        end

        assert File.exist?(file.path)
        assert_equal({ "a.txt" => "hello", "dir/b.txt" => "world" }, entries(file.path))
    ensure
        file&.close!
    end

    test "leaves no tempfile behind when the block raises" do
        pattern = File.join(Dir.tmpdir, "leaktest*.zip")
        before = Dir.glob(pattern)

        assert_raises(RuntimeError) do
            ZipWriter.to_tempfile(basename: "leaktest") { |zip| raise "boom" }
        end

        assert_equal before, Dir.glob(pattern),
            "to_tempfile must unlink its tempfile when the caller's block raises"
    end

    test "disambiguates repeated filenames" do
        taken = Set.new
        assert_equal "a.txt",     ZipWriter.unique_name("a.txt", taken)
        assert_equal "a (2).txt", ZipWriter.unique_name("a.txt", taken)
        assert_equal "a (3).txt", ZipWriter.unique_name("a.txt", taken)
        assert_equal "b.txt",     ZipWriter.unique_name("b.txt", taken)
    end

    test "disambiguates filenames without an extension" do
        taken = Set.new
        assert_equal "Makefile",     ZipWriter.unique_name("Makefile", taken)
        assert_equal "Makefile (2)", ZipWriter.unique_name("Makefile", taken)
    end

    test "does not collide when the disambiguated name is itself submitted" do
        taken = Set.new
        assert_equal "a.txt",     ZipWriter.unique_name("a.txt", taken)
        assert_equal "a (2).txt", ZipWriter.unique_name("a (2).txt", taken)
        assert_equal "a (3).txt", ZipWriter.unique_name("a.txt", taken)
    end

    test "streams attachments without reading them whole" do
        submit = submits(:one)
        submit.files.attach(io: StringIO.new("contents"), filename: "x.py", content_type: "text/plain")

        file = ZipWriter.to_tempfile do |zip|
            ZipWriter.add_attachment(zip, "x.py", submit.files.first)
        end

        assert_equal({ "x.py" => "contents" }, entries(file.path))
    ensure
        file&.close!
    end

end
