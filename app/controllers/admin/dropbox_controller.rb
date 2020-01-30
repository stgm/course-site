class Admin::DropboxController < ApplicationController

	before_action :authorize
	before_action :require_admin

	# redirects to dropbox to allow oauth confirmation
	def connect
		redirect_to Dropbox::Client.get_auth_url(url_for action: 'oauth', protocol: 'https')
	end

	# endpoint after dropbox confirmation, checks connection and saves
	def oauth
		Dropbox::Client.process_authorization(params[:code])
		redirect_to :root
	end
	
end
