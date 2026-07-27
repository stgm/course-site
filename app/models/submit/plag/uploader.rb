class Submit::Plag::Uploader

    def initialize(config)
        raise if ENV["PLAG_SERVER_KEY"].blank?
        @config_items = config.merge({ 'api-token': ENV["PLAG_SERVER_KEY"] })
        @c = Curl::Easy.new(@config_items["server"])
        @c.multipart_form_post = true
    end

    # takes a path, not an IO: the three-argument form of PostField.file is
    # (name, local_path, remote_name) and makes libcurl stream the upload straight off
    # disk, where the block form would hold the whole file in memory for the duration
    # of the POST. the remote name stays "files", as it was with the block form.
    #
    def upload(path)
        json = @config_items.map { |k, v| Curl::PostField.content(k.to_s, v) }
        f = Curl::PostField.file("files", path, "files")
        f.content_type = "application/octet-stream"
        @c.http_post f, *json
    end

    def close
        @c.close
    end

end
