class CheckSender

    def self.enabled?
        ENV["CHECK_SERVER_URL"].present? && ENV["CHECK_SERVER_SECRET"].present?
    end

    def initialize(zipped_attachments, tool_config:, callback_url:)
        @server_url = ENV["CHECK_SERVER_URL"]
        @server_secret = ENV["CHECK_SERVER_SECRET"]

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
                webhook: 'https://minprog.requestcatcher.com/test',# @callback_url,
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
