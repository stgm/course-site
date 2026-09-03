# Builds zip files on disk instead without keeping much in memory.

class ZipWriter

    # Builds a zip in a temp file and returns it, closed and ready to read.
    #
    # Callers in a request should provide the temp file to Rack so it gets cleaned up
    # once the response has been sent:
    #
    #   file = ZipWriter.to_tempfile { |zip| ... }
    #   request.env["rack.tempfiles"] << file
    #   send_file file.path, ...
    def self.to_tempfile(basename: "zip")
        file = Tempfile.new([ basename, ".zip" ], binmode: true)
        begin
            Zip::OutputStream.open(file.path) { |zip| yield zip }
        rescue
            file.close!
            raise
        end
        file
    end

    # add open file
    def self.add_stream(zip, name, io)
        zip.put_next_entry(name)
        IO.copy_stream(io, zip)
    end

    # add from ActiveStorage
    def self.add_attachment(zip, name, attachment)
        attachment.blob.open { |tempfile| add_stream(zip, name, tempfile) }
    end

    # zip entries must be unique, add counter to name if needed
    def self.unique_name(name, taken)
        return name if taken.add?(name)

        extension = File.extname(name)
        base = File.basename(name, extension)
        counter = 2
        counter += 1 until taken.add?("#{base} (#{counter})#{extension}")
        "#{base} (#{counter})#{extension}"
    end

end
