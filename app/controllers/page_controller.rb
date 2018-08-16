require 'dropbox'

class PageController < ApplicationController

	prepend_before_action CASClient::Frameworks::Rails::GatewayFilter, only: [ :homepage ]
	prepend_before_action CASClient::Frameworks::Rails::GatewayFilter, unless: :request_from_local_network?, except: [ :homepage ]
	prepend_before_action CASClient::Frameworks::Rails::Filter, if: :request_from_local_network?, except: [ :homepage ]

	before_action :register_attendance
	
	def homepage
		# redirect_to page_mobile_home_path and return if request.user_agent =~ /Mobile|webOS/ && current_user.staff?
		
		# the normal homepage is the page without a parent section
		# @page = Page.where(:section_id => nil).first
		
		if not Page.any?
			if User.admin.any?
				redirect_to config_path and return
			else
				redirect_to welcome_register_path and return
			end
		end
	
		if logged_in?
			# if not found, course is presumably empty, redirect to onboarding
			# TODO make if no course connected
			# if Settings['homepage'].nil?
			# 	redirect_to welcome_path and return
			# end

			@schedules = Schedule.all
			@student = User.includes(:hands, :notes).find(current_user)
			@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', current_user.id).order('grades.created_at desc')
			@groups = Group.order(:name)
			@note = Note.new(student_id: @student.id)
		
			@items = []
			@items += @student.submits.where("submitted_at not null").to_a
			@items += @grades.to_a
			# @items += @alerts.to_a
			# @items += @student.hands.to_a
			# @items += @student.notes.to_a
			@items = @items.sort { |a,b| b.created_at <=> a.created_at }
			
			if current_user.senior?
				# if params[:pset_id]
					# @pset = Pset.find(params[:pset_id])
				# else
					# @pset = Pset.order(:order).first
				# end
				# @psets = Pset.order(:order)
				@groups = current_user.schedule.groups.order(:name)
				@new_students = current_user.schedule.users.not_staff.registered
			end
		
			render "timeline/timeline" and return
		else
			# if not found, course is presumably empty, redirect to onboarding
			if Settings['homepage']
				redirect_to Settings['homepage'] and return
			else
				render text: "Website is empty." and return
			end
		end
		
		# @has_form = @page.pset && @page.pset.form

		render :index
	end
	
	def mobile_home
	end
	
	def index
		# find section by url and bail out if not found
		@section = Section.where(:slug => params[:section]).first
	    raise ActionController::RoutingError.new('Not Found') if !@section
		
		# find page by url in section and bail out if not found
		@page = @section.pages.where(:slug => params[:page]).first		
	    raise ActionController::RoutingError.new('Not Found') if !@page
		
		if @page.pset && current_user.can_submit?
			@has_form = @page.pset.form
			@submitted = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).count > 0
		end
		
		render :index
	end
	
	def submit
		if !session[:cas_user]
			redirect_to(:back, alert: 'Please login again before submitting.') and return
		end
		
		page = Page.find(params[:page_id])
		pset = page.pset

		if (pset.form || pset.files.any?) && !Dropbox.connected?
			redirect_to(:back, flash: { alert: "<b>There is a problem with submitting!</b> Warn your professor immediately and mention Dropbox.".html_safe }) and return
		end
		
		form_text = render_form_text(params[:a])

		# upload to dropbox
		if pset.form || pset.files
			begin
				upload_to_dropbox(session[:cas_user], current_user.name,
					Settings.submit_directory, pset.name, params[:notes], form_text, params[:f])
			rescue
				redirect_to(:back, flash: { alert: "<b>There was a problem uploading your submission! Please try again.</b> If the problem persists, contact your instructor.".html_safe }) and return
			end
		end

		# create submit record
		submit = Submit.where(:user_id => current_user.id, :pset_id => pset.id).first_or_initialize
		submit.submitted_at = Time.now
		submit.used_login = session[:cas_user]
		submit.url = params[:url]
		submit.submitted_files = params[:f].map { |file,info| info.original_filename } if params[:f]
		submit.save
	
		# success
		begin
			redirect_to :back
		rescue ActionController::RedirectBackError
			redirect_to :root
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

	def upload_to_dropbox(user, name, course, item, notes, form, files)
		
		dropbox_client = Dropbox.client
		dropbox_root = ENV['DROPBOX_ROOT']
		
		# cache timestamp for folder name
		item_folder = item + "__" + Time.now.to_i.to_s

		# compose info.txt file contents
		info = "student_login_id = " + user
		info += ("\nname = " + name) if name
		info += "\n\n"
		info += notes if notes

		# upload the notes
		dropbox_client.upload(File.join("/", dropbox_root, course, user, item_folder, 'info.txt'), info) if notes
		
		# upload the form
		dropbox_client.upload(File.join("/", dropbox_root, course, user, item_folder, 'form.md'), form) if form
		
		# upload all posted files
		if files
			files.each do |filename, file|
				dropbox_client.upload(File.join("/", dropbox_root, course, user, item_folder, file.original_filename), file.read, autorename: true)
			end
		end

	end
	

end
