class Tracking::RegisterController < ActionController::Base
	
	def identify

		render json: { error: "Pairing code is missing." } and return if params[:code].blank?
		
		current_user = User.find_by_token(params[:code].to_i)
		
		render json: { error: "Pairing code is invalid." } and return if !current_user
		
		if current_user.valid_profile?
			current_user.generate_token!
			render json: { token: current_user.token, beacon_id: ENV['BEACON_UUID'], icon: Settings['icon'] }
		else
			render json: { error: "Not registered yet." }
		end
		
	end
	
end
