class Admin::DropboxController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	# key entry page, also shows if already having a session
	def index
		@dropbox_linked = Dropbox.connected?
	end

	# redirects to dropbox to allow oauth confirmation
	def connect
		redirect_to Dropbox.get_dropbox_auth_url(admin_dropbox_oauth_url)
	end

	# endpoint after dropbox confirmation, checks connection and saves
	def oauth
		if params[:not_approved] == 'true'
			redirect_to admin_dropbox_path, flash: { error: 'You just cancelled, didn\'t you?' }
		else
			Dropbox.process_authorization
			redirect_to :root
		end
	end

end
