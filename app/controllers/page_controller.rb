class PageController < ApplicationController
	
	prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter
	before_filter :redirect_to_profile
	
	def homepage
		# the homepage is the page without a parent section
		@page = Page.where(:section_id => nil).first
		
		# if not found, course is presumably empty, redirect to onboarding
		redirect_to welcome_url and return if @page.nil?
		
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
		
		@comments = @page.comment_threads.includes(:comments).order('created_at desc').all
		@has_form = @page.pset && @page.pset.form
		
	end
	
	def submit
		
		dropbox = DropboxConnection.new
		# upload = params[:attachment]
		
		if dropbox.linked?
			# validate file size
			# if upload && upload.size > 504800
			# 	render :text => "Your file is too big. Make sure you only submit your source files. (Ask your assistant what this means!)"
			# 	return
			# end

			# validate form
			# if !upload || params[:course] == "" || params[:pset] == "" || params[:name] == ""
			# 	render :text => "You can't submit without choosing your course and pset, and attaching a file."
			# 	return
			# end
			
			page = Page.where(:id => params[:page_id]).first
			if page.nil?
				flash[:error] = "<b>Error!</b> Submit fail. Try again.".html_safe
				redirect_to(:back)
				return
			end
			
			form_text = nil
			if params[:a]
				form_text = ""
				params[:a].each do |key, value|
					form_text += "#{key}\n\n"
					form_text += "#{value}\n\n"
				end
			end
			
			pset = Page.find(params[:page_id]).pset

			# upload to dropbox
			dropbox.submit(current_user.uvanetid, current_user.name, Course.course['submit'], pset.name, params[:notes], form_text, params[:f])

			# create submit record
			submit = Submit.where(:user_id => current_user.id, :pset_id => pset.id).first_or_initialize
			submit.submitted_at = Time.now
			submit.save
			
			# success
			redirect_to(:back, :notice => "<b>Thanks for submitting!</b> Everything was successfully uploaded.".html_safe)
		else			
			render :text => 'Dropbox is not linked, please warn your professor immediately.'
		end

	end
	
	def save_answers

		if logged_in?

			pset = Page.find(params[:page_id]).pset
			
			@answer = Answer.new(:user_id => current_user.id, :pset_id => pset.id)
			@answer.answer_data = params[:a].to_json

			respond_to do |format|
				if @answer.save
					format.json { render :json => @answer, :status => :created }
				else
					format.json { render :json => @answer.errors, :status => :unprocessable_entity }
				end
			end

		else
			format.json { render :json => 'huh', :status => :unprocessable_entity }
		end

	end
	
	
	private
	
	def redirect_to_profile
		if logged_in? && (current_user.name.nil? || current_user.name == '')
			redirect_to :controller => 'profile'
		end
	end

end
