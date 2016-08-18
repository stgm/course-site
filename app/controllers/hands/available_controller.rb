class Hands::AvailableController < ApplicationController

	def index
		@user = current_user
		real_time = DateTime.now
		# cutoff_time = DateTime.new(real_time.year, real_time.month, real_time.mday, real_time.hour, Rational)
		cutoff_time = real_time.beginning_of_hour
		cutoff_time -= 1.hours if cutoff_time.hour % 2 == 0
		@option1 = cutoff_time + 2.hours
		@option2 = cutoff_time + 4.hours
		@optionU = 1.hour.ago
		@available = ((@user.available or DateTime.now) > DateTime.now)
		@available_string = @available ? "" : "not"
	end
	
	def set
		current_user.update_attribute(:available, params[:until])
		redirect_to :back
	end

end
