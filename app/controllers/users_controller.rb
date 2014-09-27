class UsersController < ApplicationController
	
	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	respond_to :json

	def update
		p = User.find(params[:id])
		p.update_attributes!(params[:user])
		respond_with p
	end
	
end
