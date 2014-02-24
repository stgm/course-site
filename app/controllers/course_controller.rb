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
		
		if Track.any?

			# if tracks have been defined in course.yml
			@groups = []
			@done = []
			all_grouped_users = []
			all_psets = []
			Track.all.each do |track|
				psets = track.psets.order("psets_tracks.id")
				users = track.users.from_term(params[:term]).having_status(params[:status]).order("registrations.term, registrations.status")
				all_grouped_users += users
				all_psets += psets
				title = track.name
				@groups << { psets: psets, users: users, title: title, track:track }
			end
			
			@groupless = User.includes({ :submits => :grade }).active.not_admin.but_not(all_grouped_users).order(:name)
			@admins = User.includes({ :submits => :grade }).admin.order(:name)
			@psets = all_psets
			@title = "List users"
						
			render "grades_tracks"
			
		else

			# if tracks have NOT been defined in course.yml
			@groupless = User.active.not_admin.order(:name)
			@inactive = User.inactive.not_admin.order(:name)
			@admins = User.admin.order(:name)
			@psets = Pset.order(:name)
			@title = "List users"
			
		end
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
