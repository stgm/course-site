class SectionController < ApplicationController

	prepend_before_action CASClient::Frameworks::Rails::Filter, if: :request_from_local_network?
	
	def index
		# find section by url and bail out if not found
		@section = Section.where(:slug => params[:section]).first
	    raise ActionController::RoutingError.new('Not Found') if !@section || @section.content_page.blank?
		
		render "page/index"
	end
	
end
