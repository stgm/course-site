class Admin::SiteController < ModalController

	before_action :authorize
	before_action :require_admin

	layout 'wide'
	
	def index
		@dropbox_linked = Dropbox.connected?
		@secret = Settings.webhook_secret

		render_to_modal header: 'Site configuration'
	end
	
	#
	# allows setting arbitrary settings in the settings model
	#
	def settings
		if setting = params["settings"]
			setting.each do |k,v|
				v = v == "1" if v == "1" or v == "0"
				logger.debug "Setting #{k} to #{v.inspect}"
				Settings[k] = v
			end
		end
		head :ok
	end
	
	#
	# permissions modal
	#
	def permissions_editor
		@users = User.staff.order(:role, :name)
		@schedules = Schedule.all
		@groups = Group.all

		render_to_modal header: 'User permissions'
	end
	
	#
	# set git repository, cloning if needed
	#
	def set_git_repo
		if Settings.git_repo.present?
			# refuse to set new repo if already present (because we don't have delete/replace functionality)
			redirect_back fallback_location: '/', alert: 'You already cloned a repo once!'
		else
			Settings.git_repo = params[:repo_url]
			Settings.git_branch = params[:repo_branch]
			CourseLoader.new.run
			redirect_back fallback_location: '/', notice: 'The course content was successfully cloned.'
		end
	end

	#
	# create random secret to attach a webhook from github
	#
	def generate_secret
		secret = SecureRandom.hex(20)
		Settings.webhook_secret = secret
		redirect_back fallback_location: '/'
	end

end
