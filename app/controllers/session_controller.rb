class SessionController < ApplicationController

	before_action :authorize

	def new
		# because we ask for authorization above, this action effectively requests rack-cas to login
		redirect_to :root
	end

	def destroy
		session.delete('token')
		session.delete('cas')
		redirect_to :root
	end

end
