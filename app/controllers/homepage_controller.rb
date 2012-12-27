class HomepageController < ApplicationController

	before_filter RubyCAS::GatewayFilter
	
	def index
		@user = current_user
		@page = Page.new(:title => "huh")
		render :layout => "page"
	end

end
