class PageController < ApplicationController
	
	prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter
	before_filter :redirect_to_profile
	
	def homepage
		# the homepage is the page without a parent section
		@page = Page.where(:section_id => nil).first
		
		# if not found, course is presumably empty, redirect to onboarding
		redirect_to welcome_url and return if @page.nil?
		
		@has_form = @page.pset && @page.pset.form
		
		if current_user && load_schedule().any?
			render :index_schedule, layout:'with_schedule'
		else
			render :index
		end
	end
	
	def index
		# find section by url and bail out if not found
		@section = Section.where(:slug => params[:section]).first
		render(status:404, text:"404 Section") and return if !@section
		
		# find page by url in section and bail out if not found
		@page = @section.pages.where(:slug => params[:page]).first		
		render(status:404, text:"404 Page") and return if !@page
		
		if logged_in? && @page.pset
			@has_form = @page.pset.form
			load_form_answers() if @has_form
			@submitted = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).count > 0
		end
		
		if current_user && load_schedule().any?
			render :index_schedule, layout:'with_schedule'
		else
			render :index
		end
	end
	
	def load_form_answers
		# get cached form answers for this page / TODO FUGLY
		answer = Answer.where(:user_id => current_user.id, :pset_id => @page.pset.id).order('created_at').last
		if answer && answer.answer_data != "null" # strange behavior from JSON when given "null"
			answer = JSON.parse(answer.answer_data)
			@answer_data = {}
			answer.each do |field, value|
				@answer_data["a[#{field}]"] = value
			end
		end
	end
	
	def load_schedule
		@registrations = current_user.registrations.where("schedule_id is not null and schedule_span_id is not null")
	end
	
	def prev_in_schedule
		reg = current_user.registrations.where(id: params[:registration_id]).first
		if reg.schedule_span.present?
			reg.schedule_span = reg.schedule_span.previous if reg.schedule_span.previous.present?
		else
			reg.schedule_span = reg.schedule.schedule_spans.first
		end
		reg.save
		redirect_to :back
	end

	def next_in_schedule
		reg = current_user.registrations.where(id: params[:registration_id]).first
		reg.schedule_span = reg.schedule_span.next if reg.schedule_span.next.present?
		reg.save
		redirect_to :back
	end
	
	def submit
		if Dropbox.connected?
			dropbox = Dropbox.connection

			page = Page.find(params[:page_id])
			pset = page.pset
			form_text = render_form_text(params[:a])

			# upload to dropbox
			dropbox.submit(current_user.uvanetid, current_user.name,
			               Settings.submit_directory, pset.name, params[:notes], form_text, params[:f])

			# create submit record
			submit = Submit.where(:user_id => current_user.id, :pset_id => pset.id).first_or_initialize
			submit.submitted_at = Time.now
			submit.save
			
			# success
			redirect_to(:back)
		else			
			redirect_to(:back, flash: { error: "<b>There is a problem with submitting!</b> Warn your professor immediately and mention Dropbox.".html_safe })
		end
	end
	
	def save_answers
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
	end
	
	private
	
	# writes hash with form contents to a plain text string
	def render_form_text(form)
		form_text = nil
		if form
			form_text = ""
			form.each do |key, value|
				form_text += "#{key}\n\n"
				form_text += "#{value}\n\n"
			end
		end
		return form_text
	end
	
end
