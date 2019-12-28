class SessionController < ApplicationController

	before_action :authorize

	def new
		# because we ask for authorization above, this action effectively requests rack-cas to login
		redirect_to :root
	end

	# # TODO allow user login via secret URL, e.g. when cas is not available
	# def create
	# 	# user = User.find_by_email(params[:email])
	# 	# if user && user.authenticate(params[:password])
	# 	# 	session[:user_id] = user.id
	# 	# 	redirect_to :root, notice: "Logged in!"
	# 	# else
	# 	# 	flash.now.alert = "Email or password is invalid"
	# 	# 	render "new"
	# 	# end
	# 	redirect_to :root
	# end

	def destroy
		session.delete('cas')
		redirect_to :root, notice: "Logged out!"
	end

end
