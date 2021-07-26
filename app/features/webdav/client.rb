class Webdav::Client

    @@webdav_base = ENV['COURSE_SITE_WEBDAV_BASE']
    @@webdav_user = ENV['COURSE_SITE_WEBDAV_USER']
    @@webdav_pass = ENV['COURSE_SITE_WEBDAV_PASS']

    # check if the env variables are filled for this API to function
    def self.available?
        return @@webdav_base.present? && @@webdav_user.present? && @@webdav_pass.present?
    end

    def self.configured?
        Settings.archive_base_folder.present? && Settings.archive_course_folder
    end

    def initialize
        @base = @@webdav_base
        @user = @@webdav_user
        @pass = @@webdav_pass

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
