class WebdavUploader
    class Error < StandardError; end

    # check if the env variables are filled for this API to function
    def self.fully_configured?
        return Settings.webdav_base.present? &&
               Settings.webdav_user.present? &&
               Settings.webdav_pass.present? &&
               Settings.archive_course_folder.present?
    end

    def initialize(submit_path)
        # Submit/course_name/student_id/submit_0000000000/
        @submit_path = submit_path.delete_suffix("/") + "/"

        # https://.../webdav/
        @base = Settings.webdav_base.delete_suffix("/") + "/"
        @user = Settings.webdav_user
        @pass = Settings.webdav_pass

        @c = Curl::Easy.new
        @c.http_auth_types = :basic
        @c.username = @user
        @c.password = @pass
    end

    # Upload from an array of open file objects
    # rewind each file after sending
    def upload(files)
        files.each do |filename, file|
            upload_file(filename, file.read)
            file.rewind
        end
    end

    # Upload a single file
    def upload_file(filename, contents)
        create_path(@submit_path)
        @c.url = URI.join(@base, @submit_path, filename)
        @c.http_put contents
        raise Error, @c.status if !@c.status.start_with?("20")
    rescue => e
        raise Error, "connection to archival server failed (#{e})"
    end

    def create_path(path)
        segments = path.split("/").reject { |x|x.empty? }

        # create the full path segment by segment if it doesn't exist
        current = ""
        segments.each do |segment|
            current = File.join(current, segment)
            create_directory_if_not_exists(current.delete_prefix("/"))
        end
    end

    def create_directory_if_not_exists(path)
        @c.url = URI.join(@base, path)
        @c.get
        if @c.response_code == 404
            @c.http :MKCOL
        end
    end

    def close
        @c.close
    end

end
