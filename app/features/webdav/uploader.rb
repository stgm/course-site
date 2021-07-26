class Webdav::Uploader

    def initialize(base_path)
        @base_path = base_path
    end

    def upload(files)
        client = Webdav::Client.new
        files.each do |filename, file|
            client.upload(@base_path, filename, file.read)
        end
    end

end
