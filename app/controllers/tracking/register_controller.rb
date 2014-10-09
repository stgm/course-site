class Tracking::RegisterController < ApplicationController
	
	prepend_before_filter CASClient::Frameworks::Rails::Filter
	
	def identify
		current_user.generate_token!
		render json: { token: current_user.token, beacon_id: 'EBEFD083-70A2-47C8-9837-E7B5634DF524' }
	end
	
end
