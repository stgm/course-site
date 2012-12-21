class PageController < ApplicationController
	
	def index
		@section = Section.where(:title => params[:section]).first
		render :text => "section not found" and return if !@section
		@page = @section.pages.where(:title => params[:page]).first		
	end
	
end
