class CourseController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	# update the courseware from the linked git repository
	def import
		Course.reload
		redirect_to :back, notice: 'The course content was successfully updated.'
	end
	
	# list all psets that have not been graded since last submit
	def grades
		@groupless = User.where(active: true, done: false, group_id: nil).where("uvanetid not in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
		@done = User.where(done: true).order('name')
		@inactive = User.where(active: false).order('name')
		@admins = User.where("uvanetid in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
		@psets = Pset.order(:id)
		@title = "List users"
	end
	
	def toggle_public_grades
		Settings.public_grades = !Settings.public_grades
		redirect_to :back
	end
	
	def touch_submit
		Submit.find(params[:submit_id]).update_attribute(:submitted_at, Time.now)
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
		
		redirect_to :back, notice: 'Student groups were successfully imported.'
	end

end
