class LUploadIO < StringIO
    # string serves as in-memory container for a zipfile

    def initialize(name)
        @path = name
        super()   # the () is essential, calls no-arg initializer
    end

    def path
        @path
    end
end

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
                html = simple_markdown(GradingHelper::NBConverter.new(source).run)
                presentable_files[name+".html"] = html
            end
        end
        presentable_files
    end

    def file_names
        @files.map { |file, info| info.original_filename }
    end

    def zipped(&block)
        # if a zipfile is among submitted files, post that and ignore the rest
        submitted_zips = @files.keys.select { |x| x.end_with?(".zip") }
        if submitted_zips.any?
            zipfile = @files[submitted_zips[0]]
            if ActionDispatch::Http::UploadedFile === zipfile
                zipfile = zipfile.tempfile
                yield zipfile
            end
            if ActiveStorage::Attachment === zipfile
                zipfile.open &block
            end
        else
            zipfile = Zip::OutputStream.write_buffer(::LUploadIO.new("file.zip")) do |zio|
                @files.each do |filename, file|
                    zio.put_next_entry(filename)
                    if file.class == String
                        zio.write file
                    elsif file.class == ActiveStorage::Attachment
                        file.open do |f|
                            zio.write f.read
                        end
                    else
                        file.rewind
                        zio.write file.read
                    end
                end
            end
            # prepare for reading again
            zipfile.rewind if zipfile.respond_to?(:rewind)
            yield zipfile
        end
    end

    private

    def text_file?(name)
        return [ ".py", ".c", ".txt", ".html", ".css", ".h", ".java" ].include?(File.extname(name)) || name == "Makefile"
    end

    def notebook_file?(name)
        return [ ".ipynb" ].include?(File.extname(name))
    end

end
