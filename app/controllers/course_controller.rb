class CourseController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	#
	# update the courseware from the linked git repository
	#
	def import
		Course.reload
		redirect_to :back, notice: 'The course content was successfully updated.'
	end
	
	def export_grades
		@users = User.where(active: true).order('name')
		@psets = Pset.order(:id)
		@title = "Export grades"
	end

	#
	# ajax-only enable/disable of students
	#
	def enable
		reg = User.find(params[:id])
		reg.update_attribute(:active, params[:active])
		render :nothing => true
	end

	#
	# ajax-only done/not done of students
	#
	def done
		reg = User.find(params[:id])
		reg.update_attribute(:done, params[:done])
		render :nothing => true
	end
	
	#
	# list all submits
	#
	def grades
		@groupless = User.where(active: true, done: false, group_id: nil).where("uvanetid not in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
		@done = User.where(done: true).order('name')
		@inactive = User.where(active: false).order('name')
		@admins = User.where("uvanetid in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
		@psets = Pset.order(:id)
		@title = "List users"
	end
	
	#
	# list all submits
	#
	def track_grades
		current_track = Course.tracks[params[:track]]
		@psets = Pset.where("name" => current_track['requirements'])
		# @users = User.select("users.*, count(submits.id) as prio").joins(:submits, :psets).where("psets.name" => current_track['requirements']).where(active:true).order("prio")
		@users = User.includes(:submits, :psets).where("psets.name" => current_track['requirements']).where(active:true)
		@users = @users.sort { |a,b| a.submits.size <=> b.submits.size }
		@title = current_track['name']
	end
	
	#
	# visibility of grades by normal users
	#
	def toggle_public_grades
		Settings.public_grades = !Settings.public_grades
		redirect_to :back
	end
	
	#
	# allow access to grading module
	#
	def toggle_grading_allowed
		Settings.allow_grading = !Settings.allow_grading
		redirect_to :back
	end
	
	#
	# update submit date for single submit, in order to get it into the queue again
	#
	def touch_submit
		Submit.find(params[:submit_id]).update_attribute(:submitted_at, Time.now)
		redirect_to :back
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
