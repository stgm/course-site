class TodosController < ApplicationController

	def watch_list
		if current_user.admin?
			@watch_list = User.watching
		else
			@watch_list = current_user.students
		end
	end

end
