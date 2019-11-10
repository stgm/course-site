class DropboxController < ApplicationController

	before_action :authorize
	before_action :require_admin

	# redirects to dropbox to allow oauth confirmation
	def connect
		if Dropbox.available?
			redirect_to Dropbox.get_auth_url(url_for action: 'oauth', protocol: 'https')
		else
			redirect_back fallback_location: '/', alert: "Dropbox has not been configured server-side."
		end
	end

	# endpoint after dropbox confirmation, checks connection and saves
	def oauth
		Dropbox.process_authorization(params[:code])
		redirect_to :root
	end
	
end
