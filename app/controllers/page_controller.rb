class PageController < ApplicationController

	before_action :authorize, if: :request_from_local_network?
	before_action :validate_profile
	before_action :register_attendance
	before_action :go_location_bumper

	def index
		# find page by url and bail out if not found
		@page = Page.where(:slug => params[:slug]).first		
		raise ActionController::RoutingError.new('Not Found') if !@page

		@subpages = @page.subpages
		
		if @page.pset && current_user.can_submit?
			@has_form = @page.pset.form
			@submitted = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).first
			@grading = @submitted && @submitted.grade
		end
	end

end
