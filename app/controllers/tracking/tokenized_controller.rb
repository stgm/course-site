class Tracking::TokenizedController < ActionController::Base
	
	before_filter :validate_token
	
	def identify
		if current_user.is_admin? || current_user.is_assistant?
			render json: { role: 'assistant' }
		else
			render json: { role: 'student' }
		end
	end
	
	private
	
	def validate_token
		self.current_user = User.find_by_token(params[:token])
	end
	
end
