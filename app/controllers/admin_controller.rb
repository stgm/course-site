class AdminController < ApplicationController

	skip_before_filter :require_admin, only: [ :claim ]
	skip_before_filter :require_users, only: [ :claim ]

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	def import_do
		Course.reload
		redirect_to :back
		# render :text => "Loaded!"
	end
	
	def users
		@user = current_user
		@groupless = User.where(:group_id => nil).order('updated_at desc')
		@psets = Pset.order(:name)
		@title = "List users"
	end
	
	def dropbox
		@user = current_user
		logger.debug Settings['dropbox.session']
		@dropbox_session = Settings['dropbox.session'] != nil
		@dropbox_app_key = Settings['dropbox.app_key']
		@dropbox_app_secret = Settings['dropbox.app_secret']
	end
	
	def dropbox_save
		Settings['dropbox.app_key'] = params['dropbox_app_key']
		Settings['dropbox.app_secret'] = params['dropbox_app_secret']
		# redirect_to :back
		
		# Allows the admin user to link the course to dropbox.
		dropbox = DropboxConnection.new
		
		if not params[:oauth_token] then
			# pass to get_authorize_url a callback url that will return the user here
			redirect_to dropbox.create_session(url_for(:controller => 'dropbox', :action => 'link'))
		else
			# the user has returned from Dropbox so save the session and go away
			dropbox.authorized
			redirect_to :root
		end
		
		# render text: "Done"
	end
	
	def admins
		@user = current_user
		@admins = Settings.admins.join("\n")
	end
	
	def admins_save
		Settings.admins = params[:admins].split(/\r?\n/)
		redirect_to :back
	end
	
	def import_groups
		# this is very dependent on datanose export format: id's in col 0 and 1, group name in 7
		source = params[:paste]
		source.each_line do |line|
			next if line.strip == ""
			line = line.split("\t")
			next if line[7] == "Group"
			group = Group.where(:name => line[7]).first_or_create if line[7] != ""
			user = User.where('uvanetid in (?)', line[0..1]).first
			if user && group
				user.group = group
				user.save
			elsif user
				user.group = nil
				user.save
			end
		end
		
		redirect_to :back
	end
	
	private

	def require_admin
		redirect_to :root unless is_admin?
	end
	
end
