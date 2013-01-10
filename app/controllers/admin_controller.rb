class AdminController < ApplicationController

	before_filter RubyCAS::Filter

	def import_do
		Course.reload
		render :text => "Loaded!"
	end
	
	def users
		@user = current_user
		# @users = User.order('updated_at desc').group_by(&:group)
		@groupless = User.where(:group_id => nil).order('updated_at desc')
		@psets = Pset.order(:name)
		@title = "List users"
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

end
