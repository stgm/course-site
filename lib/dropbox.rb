require 'dropbox_sdk'

module Dropbox
	
	@@dropbox_key = ENV['DROPBOX_KEY']
	@@dropbox_secret = ENV['DROPBOX_SECRET']
	@@dropbox_access_type = ENV['DROPBOX_ACCESS_TYPE']

	@@session = nil
	@@connection = nil

	def self.available?
		return @@dropbox_key.present? && @@dropbox_secret.present? && @@dropbox_access_type.present?
	end
	
	def self.connected?
		@@session ||= DropboxSession.deserialize(Settings["dropbox.session"]) if Settings['dropbox.session']
		return !!@@session && @@session.authorized?
	end

	def self.connection
		return @@connection ||= DropboxConnection.new(@@session, @@dropbox_access_type) if self.connected?
	end
	
	def self.get_dropbox_auth_url(return_url)
		# create a new session for this application
		dropbox_session = DropboxSession.new(@@dropbox_key, @@dropbox_secret)

		# store the session for when the user has returned to our app
		Settings["dropbox.session"] = dropbox_session.serialize

		return dropbox_session.get_authorize_url return_url
	end
	
	def self.process_authorization
		# we've been authorized, so now request an access_token
		
		# restore session, will automatically connect to dropbox
		dropbox_session = DropboxSession.deserialize(Settings["dropbox.session"])
		dropbox_session.get_access_token
		
		# save it for later connections
		Settings["dropbox.session"] = dropbox_session.serialize
	end
	
end
