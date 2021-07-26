class Webdav::Client

    # check if the env variables are filled for this API to function
    def self.available?
        return Settings.webdav_base.present? &&
               Settings.webdav_user.present? &&
               Settings.webdav_pass.present? &&
               Settings.archive_course_folder.present?
    end

    def initialize
        @base = Settings.webdav_base
        @user = Settings.webdav_user
        @pass = Settings.webdav_pass

        @c = Curl::Easy.new(@base)
        @c.http_auth_types = :basic
        @c.username = @user
        @c.password = @pass
    end

    def upload(path, filename, contents)
        create_path(path)
        @c.url = @base + File.join(path, filename)
        @c.http_put contents
    end

    def create_path(path)
        segments = path.split('/').reject{|x|x.empty?}

        # create the full path segment by segment if it doesn't exist
        current = ''
        segments.each do |segment|
            current = File.join(current, segment)
            create_directory_if_not_exists(current)
        end
    end

    def create_directory_if_not_exists(path)
        @c.url = @base.delete_suffix('/') + path
        @c.get
        if @c.response_code == 404
            @c.http :MKCOL
        end
    end

    def close
        @c.close
    end

end
