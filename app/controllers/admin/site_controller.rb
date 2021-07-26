class Admin::SiteController < ApplicationController

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	# Show all available site configuration options.
	def index
		@secret = Settings.webhook_secret
	end

	# Allows changing arbitrary settings in the settings model.
	def settings
		if setting = params["settings"]
			setting.each do |k,v|
				v = v == "1" if v == "1" or v == "0"
				Settings[k] = v
			end
		end
		head :ok
	end

	# Set git repository, cloning if needed.
	def set_git_repo
		if Settings.git_repo.present?
			# refuse to set new repo if already present (because we don't have delete/replace functionality)
			redirect_back fallback_location: '/', alert: 'You already cloned a repo once!'
		else
			Settings.git_repo = params[:repo_url]
			Settings.git_branch = params[:repo_branch]
			Course::Loader.new.run
			redirect_back fallback_location: '/', notice: 'The course content was successfully cloned.'
		end
	end

	# Create random secret to attach a webhook from github, which will be
	# displayed in the settings from then on.
	def generate_secret
		secret = SecureRandom.hex(20)
		Settings.webhook_secret = secret
		redirect_to admin_site_path
	end

end
