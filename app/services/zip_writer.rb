# Builds zip files on disk instead of in memory.
#
# Everything here streams: entries are copied with IO.copy_stream and the archive
# itself lives in a temp file, so peak memory is a copy buffer rather than the size
# of the archive. That matters because the app runs under Passenger with the async
# job adapter, so a single large in-memory archive permanently raises the RSS of the
# process that built it.
#
class ZipWriter

    # Builds a zip in a temp file and returns it, closed and ready to read.
    #
    # Callers in a request should hand the temp file to Rack so it gets cleaned up
    # once the response has been sent:
    #
    #   file = ZipWriter.to_tempfile { |zip| ... }
    #   request.env["rack.tempfiles"] << file
    #   send_file file.path, ...
    #
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

    # Writes one entry by streaming from an IO, never holding the whole file.
    #
    def self.add_stream(zip, name, io)
        zip.put_next_entry(name)
        IO.copy_stream(io, zip)
    end

    # ActiveStorage::Blob#open downloads to a temp file, so the blob never lands in
    # memory as a whole either.
    #
    def self.add_attachment(zip, name, attachment)
        attachment.blob.open { |tempfile| add_stream(zip, name, tempfile) }
    end

    # Zip entries must be unique; two attachments on the same submit can share a
    # filename, so disambiguate the later ones as "report (2).pdf".
    #
    def self.unique_name(name, taken)
        return name if taken.add?(name)

        extension = File.extname(name)
        base = File.basename(name, extension)
        counter = 2
        counter += 1 until taken.add?("#{base} (#{counter})#{extension}")
        "#{base} (#{counter})#{extension}"
    end

end
