module AuthenticationHelper

	def authenticated?
		return request.session['token'].present? || request.session['cas'].present?
	end
	
	def logged_in?
		return authenticated? && current_user.persisted?
	end
	
	def current_user
		return @current_user || load_current_user
	end
	
	private
	
	def load_current_user
		if authenticated? && login = Login.where(login: (request.session['cas']['user']).downcase).first
			@current_user = login.user
		else
			# use an empty user object in case of no login
			@current_user = User.new
		end
		
		return @current_user
	end
	
end
