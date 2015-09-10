class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant, except: :mark_all_public
	before_filter :require_admin, only: :mark_all_public

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
				@submit.grade.update_attributes(params[:grade])
			else
				render status: 403
			end
		else
			@submit.create_grade
			@submit.grade.update_attributes(params[:grade].merge(grader: current_user.login_id))
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
	end
	
	def mark_all_public
		@grades = Grade.where(done:true).where(public:false)
		@grades.update_all(public:true)
	end

end
