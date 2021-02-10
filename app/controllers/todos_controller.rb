class TodosController < ApplicationController

	def watch_list
		if current_user.admin?
			@watch_list = User.watching.order(:name)
		else
			@watch_list = current_user.students.order(:name)
		end
	end

end
