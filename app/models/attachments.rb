class Attachments

    include ApplicationHelper

    def initialize(files)
        @files = files || {}
        @other_files = {}
    end

    def add(filename, contents)
        @other_files[filename] = contents
    end

    def filenames
        @files.map do |file, info|
            info.original_filename
        end
    end

    def all
        @files
    end

    def presentable_file_contents
        # start with form contents
        presentable_files = @other_files.to_h

        # add uploaded files if presentable
        @files.each do |filename, file|
            name = file.original_filename
            if text_file?(name)
                if file.size < 60000
                    file.rewind and presentable_files[name] = file.read
                else
                    presentable_files[name+".txt"] = "Uploaded file was too large!"
                end
            elsif notebook_file?(name)
                file.rewind
                source = file.read
                html = render_markdown(GradingHelper::NBConverter.new(source).run, single_dollar_math: true)
                presentable_files[name+".html"] = html
            end
        end
        presentable_files
    end

    def file_names
        @files.map { |file, info| info.original_filename }
    end

    # Yields the submitted files as one zip, on disk.
    #
    # Always block-based, and every branch yields the same thing: a real file opened
    # in binary mode and positioned at 0, so callers can rely on both #read and #path.
    # rest-client needs #path to stream a multipart body, and curb needs it to upload
    # without buffering. The file is gone once the block returns.
    #
    def zipped
        # if a zipfile is among submitted files, post that and ignore the rest
        submitted_zip = @files.keys.find { |x| x.end_with?(".zip") }

        if submitted_zip
            file = @files[submitted_zip]
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
        else
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
    end

    private

    # the submitted files arrive in three shapes; hand each one to the block as an IO
    # so that nothing is read into memory as a whole
    #
    # uploaded files are rewound on both sides, so that zipping does not consume them
    # for whoever reads them next
    #
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

    def text_file?(name)
        return [ ".py", ".c", ".txt", ".html", ".css", ".h", ".java" ].include?(File.extname(name)) || name == "Makefile"
    end

    def notebook_file?(name)
        return [ ".ipynb" ].include?(File.extname(name))
    end

end
