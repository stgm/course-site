class Submit::Plag::Uploader

    def initialize(config)
        @config_items = config
        @c = Curl::Easy.new(@config_items['server'])
        @c.multipart_form_post = true
    end

    def upload(file)
        json = @config_items.map { |k,v| Curl::PostField.content(k.to_s, v) }
        @c.http_post Curl::PostField.file("files", "files"){ file.read }, *json
    end

    def close
        @c.close
    end

end
