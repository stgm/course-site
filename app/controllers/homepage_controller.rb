class HomepageController < ApplicationController

	before_filter RubyCAS::GatewayFilter
	
	def index
		@user = current_user
		@page = Page.new(:title => "Homepage")
		render :layout => "page"
	end

end
