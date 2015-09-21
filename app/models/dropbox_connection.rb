class DropboxConnection

	def initialize(session, access_type)
		@dropbox_client = DropboxClient.new(session, access_type)
	end
		
	def submit(user, name, course, item, notes, form, files)
		
		dropbox_root = ENV['DROPBOX_ROOT']
		
		# cache timestamp for folder name
		item_folder = item + "__" + Time.now.to_i.to_s

		# compose info.txt file contents
		info = "student_login_id = " + user
		info += ("\nname = " + name) if name
		info += "\n\n"
		info += notes if notes

		# upload the notes
		@dropbox_client.put_file(File.join(dropbox_root, course, user, item_folder, 'info.txt'), info) if notes
		
		# upload the form
		@dropbox_client.put_file(File.join(dropbox_root, course, user, item_folder, 'form.md'), form) if form
		
		# upload all posted files
		if files
			files.each do |filename, file|
				begin
					@dropbox_client.put_file(File.join(dropbox_root, course, user, item_folder, file.original_filename), file.read)
				rescue DropboxError
					raise "Error uploading to Dropbox"
				end
			end
		end

	end

end
