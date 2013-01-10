class AdminController < ApplicationController

	before_filter RubyCAS::Filter

	def import_do
		Course.reload
		render :text => "Loaded!"
	end
	
	def users
		@user = current_user
		@users = User.order('updated_at desc')
		@psets = Pset.order(:name)
	end

end
