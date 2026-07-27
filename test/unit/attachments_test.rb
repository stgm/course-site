require 'test_helper'

# Attachments#zipped has three consumers that each depend on a different part of its
# contract: rest-client (CheckSender) needs #path and #read, curb (the plag uploader)
# needs #path, and all of them need the file positioned at 0. Every branch has to
# yield the same kind of object, which is what these tests pin down.
#
class AttachmentsTest < ActiveSupport::TestCase

    def uploaded_file(name, contents)
        tempfile = Tempfile.new(binmode: true)
        tempfile.write(contents)
        tempfile.rewind
        ActionDispatch::Http::UploadedFile.new(
            tempfile: tempfile, filename: name, type: "application/octet-stream"
        )
    end

    def zip_of(*entries)
        Tempfile.create([ "fixture", ".zip" ], binmode: true) do |file|
            Zip::OutputStream.open(file.path) do |zip|
                entries.each { |name, contents| zip.put_next_entry(name); zip.write(contents) }
            end
            File.binread(file.path)
        end
    end

    def entries(io)
        Zip::File.open(io.path) { |zip| zip.to_h { |e| [ e.name, e.get_input_stream.read ] } }
    end

    #
    # the contract every branch has to satisfy
    #

    {
        "form contents"    => -> (t) { { "answer.txt" => "42" } },
        "an uploaded file" => -> (t) { { "code.py" => t.uploaded_file("code.py", "print(1)") } },
        "an uploaded zip"  => -> (t) { { "all.zip" => t.uploaded_file("all.zip", t.zip_of([ "a.txt", "x" ])) } },
        "a legacy zip"     => -> (t) { { "all.zip" => t.zip_of([ "a.txt", "x" ]) } }
    }.each do |description, build_files|
        test "yields a readable file positioned at 0 for #{description}" do
            yielded = nil
            Attachments.new(build_files.call(self)).zipped do |zip|
                yielded = zip
                assert_respond_to zip, :path, "consumers need #path to stream from disk"
                assert File.exist?(zip.path), "#path must point at a real file"
                assert_equal 0, zip.pos, "must be positioned at 0 so the whole file is sent"
                assert_equal File.binread(zip.path), zip.read, "must be readable to EOF"
            end
            assert_not_nil yielded, "the block must be called"
        end
    end

    test "raises rather than silently yielding nothing for an unsupported zip source" do
        assert_raises(ArgumentError) do
            Attachments.new({ "all.zip" => 1234 }).zipped { |zip| flunk "should not yield" }
        end
    end

    # a legacy submit keeps its file contents in a serialized column, so a stored zip
    # arrives as a String rather than as an upload or an attachment
    test "passes a legacy zip stored as a string straight through" do
        payload = zip_of([ "inner.py", "print(4)" ])

        Attachments.new({ "all.zip" => payload, "answer.txt" => "ignored" }).zipped do |zip|
            assert_equal({ "inner.py" => "print(4)" }, entries(zip))
        end
    end

    #
    # contents
    #

    test "zips form contents and uploaded files together" do
        attachments = Attachments.new({
            "answer.txt" => "42",
            "code.py"    => uploaded_file("code.py", "print(1)")
        })

        attachments.zipped do |zip|
            assert_equal({ "answer.txt" => "42", "code.py" => "print(1)" }, entries(zip))
        end
    end

    test "zips activestorage attachments" do
        submit = submits(:one)
        submit.files.attach(io: StringIO.new("stored"), filename: "s.py", content_type: "text/plain")

        Attachments.new({ "s.py" => submit.files.first }).zipped do |zip|
            assert_equal({ "s.py" => "stored" }, entries(zip))
        end
    end

    test "passes an uploaded zip straight through and ignores the other files" do
        payload = zip_of([ "inner.py", "print(2)" ])
        attachments = Attachments.new({
            "all.zip"    => uploaded_file("all.zip", payload),
            "answer.txt" => "ignored"
        })

        attachments.zipped do |zip|
            assert_equal({ "inner.py" => "print(2)" }, entries(zip))
        end
    end

    test "passes a stored zip attachment straight through" do
        submit = submits(:one)
        payload = zip_of([ "inner.py", "print(3)" ])
        submit.files.attach(io: StringIO.new(payload), filename: "all.zip", content_type: "application/zip")

        Attachments.new({ "all.zip" => submit.files.first }).zipped do |zip|
            assert_equal({ "inner.py" => "print(3)" }, entries(zip))
        end
    end

    test "leaves an uploaded file rewound so later steps of the submit can read it" do
        file = uploaded_file("code.py", "print(1)")
        Attachments.new({ "code.py" => file }).zipped { |zip| zip.read }
        assert_equal "print(1)", file.read, "the submit is recorded after zipping"
    end

    test "removes the zip it built once the block returns" do
        path = nil
        Attachments.new({ "answer.txt" => "42" }).zipped { |zip| path = zip.path }
        assert_not File.exist?(path), "the generated zip must not outlive the block"
    end

end
