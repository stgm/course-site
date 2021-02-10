class TodosController < ApplicationController

	before_action :set_user_scope

	def watch_list
		if current_user.admin?
			@watch_list = @user_scope.watching.order(:name)
		elsif current_user.head?
			@watch_list = @user_scope.watching.order(:name)
		else
			@watch_list = @user_scope.order(:name)
		end
	end

	private

	# limits user operations to the scope allowed for the current user
	def set_user_scope
		@user_scope = case current_user.role
		when 'assistant'
			current_user.students
		when 'head'
			current_user.schedule.students
		when 'admin'
			User.student
		end
	end

end
