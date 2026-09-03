# Manages files from incoming submissions from the web and those that
# need to be sent to the check server; the main function is to
# carefully provide a zipfile on disk to be streamed or otherwise
# passed through.

class Attachments

    def initialize(files)
        @files = files || {}
    end

    def all
        @files
    end

    # yields the submitted files as one zip on disk
    def zipped(&block)
        submitted_zip = @files.keys.find { |x| x.end_with?(".zip") }
        if submitted_zip
            # if a zipfile is among submitted files, pass that through
            # ignoring any other files
            passthrough_zip(@files[submitted_zip], &block)
        else
            build_zip(&block)
        end
    end

    private

    # yields the already-zipped submission as IO on disk
    def passthrough_zip(file)
        case file
        when ActionDispatch::Http::UploadedFile
            # already spooled to disk by Rack
            file.tempfile.rewind
            begin
                yield file.tempfile
            ensure
                file.tempfile.rewind
            end
        when ActiveStorage::Attachment
            # Blob#open downloads to a temp file
            file.open { |tempfile| yield tempfile }
        when String
            # legacy submits keep their file contents in a serialized column
            Tempfile.create([ "submit", ".zip" ], binmode: true) do |out|
                out.write(file)
                out.rewind
                yield out
            end
        else
            raise ArgumentError, "cannot pass through a #{file.class} as a zipfile"
        end
    end

    # builds a new zip on disk from the individual submitted files and yields it as IO
    def build_zip
        Tempfile.create([ "submit", ".zip" ], binmode: true) do |out|
            Zip::OutputStream.open(out.path) do |zip|
                @files.each do |filename, file|
                    with_io(file) { |io| ZipWriter.add_stream(zip, filename, io) }
                end
            end
            out.rewind
            yield out
        end
    end

    # ensures that either of the three possible formats is yielded as IO
    def with_io(file)
        case file
        when String
            yield StringIO.new(file)
        when ActiveStorage::Attachment
            file.open { |tempfile| yield tempfile }
        else
            file.rewind
            begin
                yield file
            ensure
                file.rewind
            end
        end
    end

end
