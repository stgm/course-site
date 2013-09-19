require 'dropbox_sdk'

class DropboxConnection

	def initialize

		@dropbox_config = Settings
		@dropbox_client = nil
		
		if !@dropbox_config
			raise "There is no valid settings object."
		end

		# need to authenticate first
		return if !@dropbox_config["dropbox.session"]

		# this reads an existing session for this app instance
		@dropbox_session = DropboxSession.deserialize(@dropbox_config["dropbox.session"])
		
		# session could be valid, but de-authorized
		return if !@dropbox_session.authorized?

		# open client for this request
		@dropbox_client = DropboxClient.new(@dropbox_session, @dropbox_config["dropbox.access_type"])

	end
	
	def linked?
		return (@dropbox_session and @dropbox_session.authorized?)
	end
	
	def create_session(return_to_url)
		# create a new session for this application
		dropbox_session = DropboxSession.new(@dropbox_config["dropbox.app_key"], @dropbox_config["dropbox.app_secret"])

		# store the session for when the user has returned to our app
		@dropbox_config["dropbox.session"] = dropbox_session.serialize

		return dropbox_session.get_authorize_url return_to_url
	end
	
	def authorized
		# we've been authorized, so now request an access_token
		
		# restore session, will automatically connect to dropbox
		dropbox_session = DropboxSession.deserialize(@dropbox_config["dropbox.session"])
		dropbox_session.get_access_token
		
		# save it for later connections
		@dropbox_config["dropbox.session"] = dropbox_session.serialize
	end
	
	def submit(user, name, course, item, notes, form, files)
		
		dropbox_root = "Submit"
		
		if !@dropbox_client
			raise "No session to Dropbox yet."
		end
		
		# cache timestamp for folder name
		item_folder = item + "__" + Time.now.to_i.to_s

		# compose info.txt file contents
		info = "student_login_id = " + user
		info += ("\nname = " + name) if name
		info += "\n\n"
		info += notes if notes

		# upload the notes
		response = @dropbox_client.put_file(File.join(dropbox_root, course, user, item_folder, 'info.txt'), info) if notes
		Rails.logger.debug response.inspect
		
		# upload the form
		response = @dropbox_client.put_file(File.join(dropbox_root, course, user, item_folder, 'form.md'), form) if form
		Rails.logger.debug response.inspect
		
		# upload all posted files
		if files
			files.each do |filename, file|
				response = @dropbox_client.put_file(File.join(dropbox_root, course, user, item_folder, file.original_filename), file.read)
			end
		end

	end

end
