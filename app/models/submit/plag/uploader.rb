class Submit::Plag::Uploader

    def initialize(config)
        @config_items = config
        @c = Curl::Easy.new(@config_items.server)
    end

    def upload(file)
        @c.url = @base + File.join(path, filename)
        @c.http_put contents
    end

    def close
        @c.close
    end

end
