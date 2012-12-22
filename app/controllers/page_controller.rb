class PageController < ApplicationController
	
	before_filter RubyCAS::GatewayFilter

	def index
		
		@user = current_user
		
		@section = Section.where(:slug => params[:section]).first
		render :text => "section not found" and return if !@section
		@page = @section.pages.where(:slug => params[:page]).first		
		render :text => "page not found" and return if !@page
		
	end
	
end
