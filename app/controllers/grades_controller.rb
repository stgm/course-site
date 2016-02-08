class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant, except: :mark_all_public
	before_filter :require_admin, only: :mark_all_public
	
	include GradesHelper

	def form
		@user = User.find(params[:user_id])
		@pset = Pset.find(params[:pset_id])
		@submit = Submit.where(pset_id: params[:pset_id], user_id: params[:user_id]).first
		@grade = (@submit && @submit.grade) || Grade.new
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('grades.created_at desc')
		render layout: 'full-width'
	end
	
	def save
		@submit = Submit.where(pset_id: params[:pset_id], user_id: params[:user_id]).first_or_create
		if @submit.grade
			if current_user.is_admin? || !@submit.grade.done
				@submit.grade.update!(params.require(:grade).permit(:comments, :correctness, :design, :grade, :grader, :scope, :style, :done))
				logger.info @submit.grade.inspect
				if calculated_grade = calculate_grade(@submit.grade)
					@submit.grade.update_attribute(:calculated_grade, calculated_grade*10)
				else
					@submit.grade.update_attribute(:calculated_grade, nil)
				end
			else
				render nothing: true, status: 403
			end
		else
			@submit.create_grade
			new_params = params.require(:grade).permit(:comments, :correctness, :design, :grade, :grader, :scope, :style, :done)
			@submit.grade.update!(new_params)
			@submit.grade.update!(grader: current_user.login_id)
			if calculated_grade = calculate_grade(@submit.grade)
				@submit.grade.update_attribute(:calculated_grade, calculated_grade*10)
			else
				@submit.grade.update_attribute(:calculated_grade, nil)
			end
		end
		redirect_to params[:referer]
	end
	
	def destroy
		@submit = Submit.find(params[:submit_id])
		@submit.grade.destroy if @submit.grade
		@submit.destroy
		redirect_to params[:referer]
	end
	
	def mark_all_done
		@grades = Grade.where(grader:current_user.login_id).where(done:false)
		@grades.update_all(done:true)
		render nothing:true
	end
	
	def mark_all_public
		# Submit.where(pset_id: params[:pset])
		# Group.find(params[:group]).users
		
		@grades = Grade.joins(:submit => :user).where(done:true).where(public:false)
		
		if params[:pset]
			@grades = @grades.where('submits.pset_id = ?', params[:pset])
		end
		
		if params[:group]
			@grades = @grades.where('users.group_id = ?', params[:group])
		end
		
		# @grades = Grade.where(done:true).where(public:false)
		# @grades = @grades.includes([:submit, :user => :group])
		@grades.update_all(public:true)
		render nothing:true
	end

end
