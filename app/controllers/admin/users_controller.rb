class Admin::UsersController < ApplicationController

	def export_grades
		@users = User.where(active: true).order('name')
		@psets = Pset.order(:id)
		@title = "Export grades"
		render layout:'full_width'
	end
	
	#
	# divide users into groups from a csv
	#
	def import_groups
		# this is very dependent on datanose export format: id's in col 0 and 1, group name in 7
		if source = params[:paste]
			User.update_all(group_id: nil)
			Group.delete_all
		
			source.each_line do |line|
				next if line.strip == ""
				line = line.split("\t")

				user_id = line[0..1]
				group_name = line[7] && line[7].strip
				next if !group_name || group_name == "Group"
		
				user = User.where('uvanetid in (?)', user_id).first
				if user.present? && group_name != ""
					group = Group.where(:name => group_name).first_or_create
					user.group = group
					user.save
				end
			end
		end
	
		redirect_to :back, notice: 'Student groups were successfully imported.'
	end

end
