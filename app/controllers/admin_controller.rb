class AdminController < ApplicationController

	before_filter RubyCAS::Filter

	def import_do
		Course.reload
		render :text => "Loaded!"
	end

end
