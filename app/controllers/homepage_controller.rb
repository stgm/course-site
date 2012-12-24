class HomepageController < ApplicationController

	def index
		@user = current_user
		@page = Page.new(:title => "huh")
		render :layout => "page"
	end

end
