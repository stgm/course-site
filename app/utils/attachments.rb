class LUploadIO < StringIO
	# string serves as in-memory container for a zipfile
	
	def initialize(name)
		@path = name
		super()   # the () is essential, calls no-arg initializer
	end

	def path
		@path
	end
end

class Attachments
	
	def initialize(files)
		@files = files || {}
		@other_files = {}
	end
	
	def add(filename, contents)
		@other_files[filename] = contents
	end
	
	def filenames
		@files.map do |file, info|
			info.original_filename
		end
	end
	
	def all
		@files
	end
	
	def presentable_file_contents
		# start with form contents
		presentable_files = @other_files.to_h
		
		# add uploaded files if presentable
		@files.each do |filename, file|
			name = file.original_filename
			if text_file?(name)
				if file.size < 60000
					file.rewind and presentable_files[name] = file.read
				else
					presentable_files[name] = "Uploaded file was too large!"
				end
			end
		end
		presentable_files
	end
	
	def file_names
		@files.map { |file,info| info.original_filename }
	end
	
	def zipped
		# if a zipfile is among submitted files, post that and ignore the rest
		submitted_zips = @files.keys.select { |x| x.end_with?(".zip") }
		if submitted_zips.any?
			zipfile = @files[submitted_zips[0]]
		else
			zipfile = Zip::OutputStream.write_buffer(::LUploadIO.new('file.zip')) do |zio|
				@files.each do |filename, file|
					zio.put_next_entry(filename)
					file.rewind
					zio.write file.read
				end
			end
		end
		zipfile.rewind
		zipfile
	end
	
	private
	
	def text_file?(name)
		return [".py", ".c", ".txt", ".html", ".css", ".h", ".java"].include?(File.extname(name)) || name == "Makefile"
	end
	
end
