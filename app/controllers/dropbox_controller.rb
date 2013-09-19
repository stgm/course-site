class DropboxController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	# key entry page, also shows if already having a session
	def index
		dropbox = DropboxConnection.new
		# @dropbox_session = Settings['dropbox.session'] != nil
		@dropbox_linked = dropbox.linked?
	end

	# redirects to dropbox to allow oauth confirmation
	def connect
		if params['dropbox_app_key'] == '' or params['dropbox_app_secret'] == ''
			redirect_to :back, flash: { error: 'Please do provide some actual values.' } and return
		end

		Settings['dropbox.app_key'] = params['dropbox_app_key']
		Settings['dropbox.app_secret'] = params['dropbox_app_secret']
		dropbox = DropboxConnection.new
		redirect_to dropbox.create_session(dropbox_oauth_url)
	end

	# endpoint after dropbox confirmation, checks connection and saves
	def oauth
		dropbox = DropboxConnection.new
	
		if params[:not_approved] == 'true'
			redirect_to dropbox_path, flash: { error: 'You just cancelled, didn\'t you?' }
		else
			# the user has returned from Dropbox so save the session and go away
			dropbox.authorized
			redirect_to :root
		end
	end

end
