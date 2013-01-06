require 'dropbox_sdk'

class DropboxConnection

	def initialize

		@dropbox_config = YAML::load_file("#{Rails.root}/config/dropbox.yml")
		@dropbox_client = nil
		
		if !@dropbox_config
			raise "There is no valid dropbox.yml"
		end

		# need to authenticate first
		return if !@dropbox_config["dropbox_session"]
		
		@dropbox_session = DropboxSession.deserialize(@dropbox_config["dropbox_session"])
		
		# need to authenticate again
		return if !@dropbox_session.authorized?
		
		@dropbox_client = DropboxClient.new(@dropbox_session, @dropbox_config["access_type"])

	end
	
	def linked?
		return !!@dropbox_client
	end
	
	def create_session(return_to_url)
		# create a new session for this application
		dropbox_session = DropboxSession.new(@dropbox_config["app_key"], @dropbox_config["app_secret"])

		# store the session for when the user has returned to our app
		@dropbox_config["dropbox_session"] = dropbox_session.serialize
		update_dropbox_configuration

		return dropbox_session.get_authorize_url return_to_url
	end
	
	def authorized
		# we've been authorized, so now request an access_token
		
		# restore session, will automatically connect to dropbox
		dropbox_session = DropboxSession.deserialize(@dropbox_config["dropbox_session"])
		dropbox_session.get_access_token
		
		# save it for later connections
		@dropbox_config["dropbox_session"] = dropbox_session.serialize
		update_dropbox_configuration
	end
	
	def update_dropbox_configuration
		File.open("#{Rails.root}/config/dropbox.yml", 'w') { |f| YAML.dump(@dropbox_config, f) }
	end

	def submit(user, name, course, item, notes, form, files)
		
		if !@dropbox_client
			raise "No session to Dropbox yet."
		end
		
		# cache timestamp for folder name
		item_folder = item + "__" + Time.now.to_i.to_s

		# compose info.txt file contents
		info = "id = " + user
		info += ("\nname = " + name) if name
		info += "\n\n"
		info += notes if notes

		# upload the notes
		response = @dropbox_client.put_file(File.join('SubmitTest', course, user, item_folder, 'info.txt'), notes) if notes
		Rails.logger.debug response.inspect
		
		# upload the form
		response = @dropbox_client.put_file(File.join('SubmitTest', course, user, item_folder, 'form.md'), form) if form
		Rails.logger.debug response.inspect
		
		# upload all posted files
		files.each do |filename, file|
			response = @dropbox_client.put_file(File.join('SubmitTest', course, user, item_folder, file.original_filename), file.read)
		end

	end

end
