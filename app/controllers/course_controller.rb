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

			# tracks have been defined in course.yml

			@groups = []
			@done = []
			all_grouped_users = []
			Track.all.each do |track|
				final_grade = track.final_grade
				psets = track.psets
				users = User.includes({ :submits => :grade }, :psets).where(active: true).where("psets.id" => psets).order("users.created_at")
				all_grouped_users += users
				
				# filter out all users that have gotten a final grade for this track
				if track.final_grade and not params[:done]
					users = users.select do |u|
						!u.submits.index { |s| s.pset_id == track.final_grade.id }
					end
				end
				
				title = track.name
				@groups << { psets: psets, users: users, title: title }
			end
			
			@groupless = User.where("users.id not in (?) and active = 't'", all_grouped_users).includes({ :submits => :grade })
			@inactive = User.includes({ :submits => :grade }).where(active: false).where("uvanetid not in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
			@admins = User.includes({ :submits => :grade }).where("uvanetid in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
			@psets = Pset.order(:name)
			@title = "List users"
			render "grades_tracks"
			
		else

			# tracks have NOT been defined in course.yml

			@groupless = User.where(active: true).where("uvanetid not in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
			@inactive = User.where(active: false).where("uvanetid not in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
			@admins = User.where("uvanetid in (?)", Settings['admins'] + (Settings['assistants'] or [])).order('name')
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
