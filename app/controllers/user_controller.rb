class UserController < ApplicationController
	
	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	def update
		p = User.find(params[:id])
		p.update_attributes!(params.require(:user).permit(:name, :active, :status, :mail))

		respond_to do |format|
			format.json { respond_with_bip(p) }
			format.html { redirect_to :back }
		end
	end
	
	def assign_group
		p = User.find(params[:user_id])
		g = Group.friendly.find(params[:group_id])
		
		p.group = g
		p.save
		
		redirect_to :back
	end
	
	def calculate_final_grade
		u = User.find(params[:user_id])
		u.assign_final_grade(current_user.login_id)
		redirect_to :back
	end
	
end
