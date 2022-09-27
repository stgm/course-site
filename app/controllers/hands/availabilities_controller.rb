class Hands::AvailabilitiesController < ApplicationController

	before_action :authorize
	before_action :require_staff

	layout 'hands'

	def edit
		@user = current_user
		real_time = Time.current
		cutoff_time = real_time.beginning_of_hour
		@option1 = cutoff_time + 1.hours
		@optionU = 1.hour.ago
		@available = ((@user.available or Time.current) > Time.current)
		@available_string = @available ? "" : "not"
	end
	
	def update
		current_user.update_attribute(:available, params[:until])
		redirect_to hands_path
	end

end
