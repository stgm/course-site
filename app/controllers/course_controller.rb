class CourseController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	# update the courseware from the linked git repository
	def import
		Course.reload
		redirect_to :back, notice: 'The course content was successfully updated.'
	end
	
	# list all psets that have not been graded since last submit
	def grading_list
		@submits = Submit.includes(:user, :pset, :grade).where("users.active = ? and users.done = ? and (grades.updated_at < submits.updated_at or grades.updated_at is null)", true, false).order('psets.name')
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

end
