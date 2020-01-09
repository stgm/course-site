class PageController < ApplicationController

	before_action :authorize, if: :request_from_local_network?
	before_action :register_attendance
	
	before_action :go_location_bumper
	before_action :load_navigation

	def index
		# find section by url and bail out if not found
		@section = Section.where(:slug => params[:section]).first
	    raise ActionController::RoutingError.new('Not Found') if !@section
		
		# find page by url in section and bail out if not found
		@page = @section.pages.where(:slug => params[:page]).first		
	    raise ActionController::RoutingError.new('Not Found') if !@page
		@subpages = @page.subpages
		
		if @page.pset && current_user.can_submit?
			@has_form = @page.pset.form
			@submitted = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).first
			# @submitted = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).count > 0
			@grading = @submitted && @submitted.grade
		end
	end
	
	def section
		# find section by url and bail out if not found
		@section = Section.where(:slug => params[:section]).first
	    raise ActionController::RoutingError.new('Not Found') if !@section || @section.content_page.blank?
	end
	
end
