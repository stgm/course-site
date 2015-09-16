require 'dropbox'

class DropboxController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	# redirects to dropbox to allow oauth confirmation
	def connect
		redirect_to Dropbox.get_dropbox_auth_url(dropbox_oauth_url)
	end

	# endpoint after dropbox confirmation, checks connection and saves
	def oauth
		if params[:not_approved] == 'true'
			redirect_to config_dropbox_path, flash: { alert: 'You just cancelled, didn\'t you?' }
		else
			Dropbox.process_authorization
			redirect_to :root
		end
	end
	
end
