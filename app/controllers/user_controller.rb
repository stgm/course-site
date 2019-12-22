class UserController < ApplicationController
	
	include ApplicationHelper
	
	before_action :authorize
	before_action :require_senior
	before_action :require_admin, only: :set_permissions

	# GET /user/:id.js
	def show
		@schedules = Schedule.all
		@student = User.includes(:hands, :notes).find(params[:id])
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @student.id).order('grades.created_at desc')
		@groups = @student.schedule.groups.order(:name) if @student.schedule
		@note = Note.new(student_id: @student.id)
		
		@items = []
		@items += @student.submits.where("submitted_at not null").to_a
		@items += @grades.to_a
		@items += @student.hands.to_a
		@items = @items.sort { |a,b| b.created_at <=> a.created_at }
		
		@hands = @student.hands.where("note is not null").order("created_at desc")
		@notes = @student.notes.order("created_at desc")
		
		@psets = Pset.order('"psets"."order" is null, "psets"."order"')
	end
	
	# PUT /user/:id
	def update
		p = User.find(params[:id])
		p.update_attributes!(params.require(:user).permit(:name, :active, :done, :status, :mail, :avatar, :notes, :schedule_id, :alarm, :role))

		respond_to do |format|
			format.json { respond_with_bip(p) }
			format.html { redirect_back fallback_location: '/' }
		end
	end
	
	# PUT /user/:user_id/admin
	def admin
		p = User.find(params[:user_id])
		p.update_attributes!(params.require(:user).permit(:role))

		respond_to do |format|
			format.json { respond_with_bip(p) }
			format.html { redirect_back fallback_location: '/' }
		end
	end
	
	def set_permissions
		user = User.find(params[:user_id])
		
		if params[:schedule_id]
			schedule = Schedule.find(params[:schedule_id])
			user.schedules << schedule
		end

		if params[:group_id]
			group = Group.find(params[:group_id])
			user.groups << group
		end

		respond_to do |format|
			format.html { redirect_back fallback_location: '/' }
		end
	end
	
	def remove_permissions
		user = User.find(params[:user_id])
		
		if params[:schedule_id]
			schedule = Schedule.find(params[:schedule_id])
			user.schedules.delete(schedule)
		end

		if params[:group_id]
			group = Group.find(params[:group_id])
			user.groups.delete(group)
		end

		redirect_back fallback_location: '/'
	end

	def set_alarm
		p = User.find(params[:user_id])
		a = params[:alarm]
		puts params[:alarm].inspect
		p.notes.create(text: "#{a == "false" ? 'Removed' : 'Added'} alarm", author_id: current_user.id)
		p.update_attribute(:alarm, a)
		redirect_back fallback_location: '/'
	end
	
	def assign_group
		p = User.find(params[:user_id])
		g = Group.friendly.find(params[:group_id])
		
		p.group = g
		p.save
		
		redirect_back fallback_location: '/'
	end
	
	def assign_schedule
		p = User.find(params[:user_id])
		g = Schedule.find(params[:schedule_id])
		
		p.schedule = g
		p.group = nil
		p.save
		
		redirect_back fallback_location: '/'
	end
	
	def calculate_final_grade
		# feature has to be enabled in grading.yml - otherwise play stupid
		raise ActionController::RoutingError.new('Not Found') if not GradeTools.available?

		u = User.find(params[:user_id])
		result = u.assign_final_grade(current_user)
		Settings.debug_alert = simple_markdown("#{result}\n".html_safe)
		redirect_back fallback_location: '/'
	end
	
end
