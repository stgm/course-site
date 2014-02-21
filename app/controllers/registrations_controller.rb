class RegistrationsController < ApplicationController
	
	respond_to :json

	def update
		p = Registration.find(params[:id])
		p.update_attributes!(params[:registration])
		respond_with p
	end

end
