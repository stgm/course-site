class PageController < ApplicationController
	
	before_filter RubyCAS::GatewayFilter
	
	def index
		
		# find section by url and bail out if not found
		@section = Section.where(:slug => params[:section]).first
		render :text => "section not found" and return if !@section
		
		# find page by url in section and bail out if not found
		@page = @section.pages.where(:slug => params[:page]).first		
		render :text => "page not found" and return if !@page
		
		@user = current_user
		
		# get cached form answers for this page / TODO FUGLY
		if logged_in?
			answer = Answer.where(:user_id => @user.id, :page_id => @page.id).first
			if answer
				answer = JSON.parse(answer.answer_data)
				@answer_data = {}
				answer.each do |field, value|
					@answer_data["a[#{field}]"] = value
				end
				logger.debug @answer_data
			end
		end
		
	end

	def homepage
		@page = Page.where(:section_id => nil).first		
		render :text => "page not found" and return if !@page
		
		@user = current_user
		render :index
	end
	
	
end
