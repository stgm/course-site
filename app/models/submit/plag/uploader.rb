class Submit::Plag::Uploader

    def initialize(config)
        raise if ENV['PLAG_SERVER_KEY'].blank?
        @config_items = config.merge({ key: ENV['PLAG_SERVER_KEY'] })
        @c = Curl::Easy.new(@config_items['server'])
        @c.multipart_form_post = true
    end

    def upload(file)
        json = @config_items.map { |k,v| Curl::PostField.content(k.to_s, v) }
        f = Curl::PostField.file("files", "files"){ file.read }
        f.content_type = 'application/octet-stream'
        @c.http_post f, *json
    end

    def close
        @c.close
    end

end
