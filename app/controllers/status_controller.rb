class StatusController < ApplicationController

	before_action :authorize
	before_action :require_senior
	
	def index
		if current_user.admin?
			scope = Hand
		else
			scope = current_user.schedule.hands
		end
		@updates = scope.where("note is not null and note != ''").order("updated_at desc")
	end

end
