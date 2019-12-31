class Hands::LocationController < ApplicationController

	before_action :authorize

	def update
		if !params[:location].blank?
			current_user.update!(last_known_location: params[:location])
		end
	
		# index
		respond_to do |format|
			format.html { redirect_to "/" }
			format.js { index }
		end
	end

end
