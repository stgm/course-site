class UsersController < ApplicationController
	
	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	def update
		p = User.find(params[:id])
		p.update_attributes!(params[:user])
		render json: p
	end
	
end
