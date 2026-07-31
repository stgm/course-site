require 'test_helper'
require_relative '../support/zip_inspection'

class ZipWriterTest < ActiveSupport::TestCase

    include ZipInspection

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

    #
    # the format itself, checked with something other than rubyzip
    #

    test "writes an archive that other unzippers can read" do
        file = ZipWriter.to_tempfile(basename: "external") do |zip|
            ZipWriter.add_stream(zip, "a.txt", StringIO.new("hello"))
            ZipWriter.add_stream(zip, "dir/b.txt", StringIO.new("world" * 1000))
        end

        assert_readable_by_unzip(file.path)
    ensure
        file&.close!
    end

    test "does not mark entries as Zip64" do
        file = ZipWriter.to_tempfile(basename: "plain") do |zip|
            ZipWriter.add_stream(zip, "a.txt", StringIO.new("hello"))
        end

        assert_not_zip64(file.path)
    ensure
        file&.close!
    end

    # students hand in files called "opgave-café.py"; the name has to come back out with
    # the bytes it went in with, whatever encoding rubyzip labels it
    #
    test "round-trips a non-ASCII entry name" do
        name = "opgave-café.py"

        file = ZipWriter.to_tempfile(basename: "unicode") do |zip|
            ZipWriter.add_stream(zip, name, StringIO.new("print(1)"))
        end

        written = entries(file.path).keys.first
        assert_equal name.b, written.b
        assert_readable_by_unzip(file.path)
    ensure
        file&.close!
    end

    # a submit can contain an empty file, and an entry of unknown-then-zero length is the
    # edge the Zip64 "might not know the size yet" branch keys off
    #
    test "writes an empty entry" do
        file = ZipWriter.to_tempfile(basename: "empty") do |zip|
            ZipWriter.add_stream(zip, "empty.txt", StringIO.new(""))
            ZipWriter.add_stream(zip, "a.txt", StringIO.new("hello"))
        end

        assert_equal({ "empty.txt" => "", "a.txt" => "hello" }, entries(file.path))
        assert_readable_by_unzip(file.path)
        assert_not_zip64(file.path)
    ensure
        file&.close!
    end

end
