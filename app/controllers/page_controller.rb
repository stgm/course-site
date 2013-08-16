class PageController < ApplicationController
	
	prepend_before_filter RubyCAS::GatewayFilter
	before_filter :redirect_to_profile
	
	def homepage
		@page = Page.where(:section_id => nil).first || Page.new(:title => 'Empty course website')		
		@user = current_user
		@comments = @page.comment_threads.includes(:comments).order('created_at desc').all
		@has_form = @page.pset && @page.pset.form
		render :index
	end
	
	def index
		# find section by url and bail out if not found
		@section = Section.where(:slug => params[:section]).first
		render :text => "section not found" and return if !@section
		
		# find page by url in section and bail out if not found
		@page = @section.pages.where(:slug => params[:page]).first		
		render :text => "page not found" and return if !@page
		
		@user = current_user
		
		# get cached form answers for this page / TODO FUGLY
		if logged_in? && @page.pset
			answer = Answer.where(:user_id => @user.id, :pset_id => @page.pset.id).order('created_at').last
			if answer && answer.answer_data != "null" # strange behavior from JSON when given "null"
				answer = JSON.parse(answer.answer_data)
				@answer_data = {}
				answer.each do |field, value|
					@answer_data["a[#{field}]"] = value
				end
			end
			@submitted = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).count > 0
		end
		
		@comments = @page.comment_threads.includes(:comments).order(:created_at => :desc).all
		
	end
	
	private
	
	def redirect_to_profile
		if logged_in? && (current_user.name.nil? || current_user.name == '')
			redirect_to :controller => 'homepage', :action => 'profile'
		end
	end

end
