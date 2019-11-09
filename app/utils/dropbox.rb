module Dropbox
	
	@@dropbox_key = ENV['DROPBOX_KEY']
	@@dropbox_secret = ENV['DROPBOX_SECRET']
	@@dropbox_access_type = ENV['DROPBOX_ACCESS_TYPE']
	
	@@root_folder = "/Submit"

	@@client = nil
	@@return_url = nil

	# check basic requirements for this API to function
	def self.available?
		return @@dropbox_key.present? && @@dropbox_secret.present? && @@dropbox_access_type.present?
	end
	
	# see if we're already connected (dropbox connections do not expire)
	def self.connected?
		return !!Settings['dropbox.session']
	end

	# get a reference to a client object
	def self.client
		return @@client ||= DropboxApi::Client.new(Settings["dropbox.session"]) if Settings['dropbox.session']
	end
	
	def self.root_folder
		@@root_folder
	end
	
	# is able to download a (small?) file by path; only returns contents, no metadata
	def self.download(path)
		contents = ""
		# x would be the metadata
		x = self.client.download(path) do |chunk|
			contents << chunk
		end
		return contents
	end
	
	# start oauth authentication process, returning the url at Dropbox to redirect to
	def self.get_auth_url(return_url)
		@@return_url = return_url
		url = authenticator.authorize_url redirect_uri: @@return_url
		return url
	end
	
	# process data returned from Dropbox, assumming success, and store the access token
	def self.process_authorization(code)
		auth_bearer = authenticator.get_token(code, :redirect_uri => @@return_url)
		token = auth_bearer.token # This line is step 5 in the diagram.
		Settings['dropbox.session'] = token
	end
	
	private

	# return authenticator instance, using the right globals
	def self.authenticator
		DropboxApi::Authenticator.new(@@dropbox_key, @@dropbox_secret)
	end

end
