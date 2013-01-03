class DropboxController < ApplicationController

	before_filter RubyCAS::Filter

	def link
		# Allows the admin user to link the course to dropbox.
		dropbox = DropboxConnection.new
		
		if not params[:oauth_token] then
			# pass to get_authorize_url a callback url that will return the user here
			redirect_to dropbox.create_session(url_for(:action => 'link'))
		else
			# the user has returned from Dropbox so save the session and go away
			dropbox.authorized
			redirect_to :root
		end
	end

end
