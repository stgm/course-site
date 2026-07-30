class CheckSender

    def self.enabled?
        AppConfig.check_server_configured?
    end

    def initialize(zipped_attachments, tool_config:, callback_url:)
        @server_url = AppConfig.check_server_url
        @server_secret = AppConfig.check_server_secret

        @zipped_attachments = zipped_attachments
        @tool_config = tool_config
        @callback_url = callback_url
    end

    def call
        endpoint = RestClient::Resource.new(
            URI.join(@server_url, @tool_config["tool"]).to_s,
            verify_ssl: OpenSSL::SSL::VERIFY_NONE)

        begin
            opts = {
                file: @zipped_attachments,
                password: @server_secret,
                webhook: @callback_url,
                multipart: true
            }
            # and add slug/repo/args from the config file
            config_opts = @tool_config.slice("slug", "repo", "args")

            response = endpoint.post(opts.merge(config_opts))
            parsed = JSON.parse(response.body)["id"]
            if !parsed
                return "FOUT: {opts.merge(config_opts)}"
            end
            return parsed
        rescue RestClient::ExceptionWithResponse => e
            return "FOUT: #{@zipped_attachments.inspect} #{e.response.raw_headers.inspect} #{e.response}"
        end
    end

end
