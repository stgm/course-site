class UsersController < ApplicationController
	
	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	def update
		p = User.find(params[:id])
		p.update_attributes!(params.require(:user).permit(:name, :active))

		respond_to do |format|
			format.json { respond_with_bip(p) }
		end
	end
	
end
