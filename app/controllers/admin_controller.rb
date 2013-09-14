class AdminController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	def import_do
		Course.reload
		redirect_to :back
		# render :text => "Loaded!"
	end
	
	def grading_list
		@submits = Submit.includes(:user, :pset, :grade).where("users.active = ? and (grades.updated_at < submits.updated_at or grades.updated_at is null)", true).order('psets.name')
	end
	
	def dropbox
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
			redirect_to dropbox.create_session(url_for(:controller => 'admin', :action => 'link'))
		else
			# the user has returned from Dropbox so save the session and go away
			dropbox.authorized
			redirect_to :root
		end
		
		# render text: "Done"
	end
	
	def admins
		@admins = Settings.admins.join("\n")
		@assistants = (Settings.assistants || []).join("\n")
	end
	
	def admins_save
		Settings.admins = params[:admins].split(/\r?\n/)
		redirect_to :back
	end
	
	def assistants_save
		Settings.assistants = params[:assistants].split(/\r?\n/)
		redirect_to :back
	end
	
	def import_groups
		# this is very dependent on datanose export format: id's in col 0 and 1, group name in 7
		if source = params[:paste]
			User.update_all(group_id: nil)
			Group.delete_all
			
			source.each_line do |line|
				next if line.strip == ""
				line = line.split("\t")

				user_id = line[0..1]
				group_name = line[7].strip
				next if group_name == "Group"
			
				group = Group.where(:name => group_name).first_or_create if group_name != ""
				user = User.where('uvanetid in (?)', user_id).first

				if user && group
					user.group = group
					user.save
				elsif user
					user.group = nil
					user.save
				end
			end
		end
		
		redirect_to :back
	end
	
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
