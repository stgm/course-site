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
	
	def add_student
		Track.find(params[:track_id]).users << User.where(uvanetid:params[:student_id]).first_or_create
		render nothing: true, status: 200
	end
	
	def remove_student
		Track.find(params[:track_id]).users.delete(User.where(uvanetid:params[:student_id]))
		logger.debug Track.find(params[:track_id]).users.inspect
		logger.debug User.where(uvanetid:params[:student_id]).inspect
		redirect_to :back
	end

	#
	# list all submits
	#
	def grades
		if Track.any?
			grades_tracks
		else
			grades_groups
		end
	end
	
	def grades_groups
		# if tracks have NOT been defined in course.yml
		@groupless = User.active.not_admin.order(:name)
		@inactive = User.inactive.not_admin.order(:name)
		@admins = User.admin.order(:name)
		@psets = Pset.order(:name)
		@title = 'List users'
		render 'grades_groups', layout:'full_width'
	end
	
	def grades_tracks
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
		
		@groupless = User.includes({ :submits => :grade }).not_admin.but_not(all_grouped_users).order(:name)
		@admins = User.includes({ :submits => :grade }).admin.order(:name)
		@psets = all_psets
		@title = 'List users'
					
		render 'grades_tracks', layout:'full_width'
	end
	
	def toggle_public_grades
		Settings.public_grades = !Settings.public_grades
		redirect_to :back
	end
	
	def toggle_grading_allowed
		Settings.allow_grading = !Settings.allow_grading
		redirect_to :back
	end
	
	def toggle_send_grade_mails
		Settings.send_grade_mails = !Settings.send_grade_mails
		redirect_to :back
	end
	
	#
	# update submit date for single submit, in order to get it into the queue again
	#
	def touch_submit
		Submit.find(params[:submit_id]).update_attribute(:submitted_at, Time.now)
		redirect_to :back
	end
	
end
