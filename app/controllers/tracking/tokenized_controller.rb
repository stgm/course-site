class Tracking::TokenizedController < ActionController::Base
	
	before_filter :current_user
	
	def identify
		if !!current_user
			if current_user.is_admin? || current_user.is_assistant?
				render json: { role: 'assistant' }
			else
				render json: { role: 'student' }
			end
		else
			render json: { error: 'No valid token.' }
		end
	end
	
	private
	
	def current_user
		return false if params[:token].blank?
		@current_user ||= User.find_by_token(params[:token])
	end
	
end
