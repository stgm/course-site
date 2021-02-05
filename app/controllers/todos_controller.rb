class TodosController < ApplicationController

	def watch_list
		@watch_list = User.watching
	end

end
