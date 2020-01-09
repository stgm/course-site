class Dropbox::Uploader
	
	def initialize(base_path)
		@base_path = base_path
	end

	def upload(files)
		dropbox = Dropbox::Client.client
		files.each do |filename, file|
			filename = File.join(@base_path, file.original_filename)
			dropbox.upload(filename, file.read, autorename: true)
		end
	end

end
