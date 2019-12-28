require 'dropbox'

class LUploadIO < StringIO
	def initialize(name)
		@path = name
		super()   # the () is essential, calls no-arg initializer
	end

	def path
		@path
	end
end

class PageController < ApplicationController

	before_action :authorize, if: :request_from_local_network?
	before_action :register_attendance
	
	before_action :go_location_bumper
	before_action :load_navigation
	before_action :load_schedule

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
	
	def submit
		# we may get here after expiry of the session if someone doesn't reload now and then
		if not logged_in?
			redirect_back(fallback_location: '/', alert: 'Please login again before submitting.') and return
		end

		# is the total upload size acceptable? (10MiB)
		if request.content_length > 9999999
			redirect_back(fallback_location: '/', alert: "Your files are too big somehow! Please check what you're uploading or ask your teacher.") and return
		end
		
		page = Page.find(params[:page_id])
		pset = page.pset

		folder_name = pset.name + "__" + Time.now.to_i.to_s

		if (pset.form || pset.files.any?) && (!Dropbox.connected? || Settings.dropbox_folder_name.blank?)
			redirect_back(fallback_location: '/', alert: '<b>There is a problem with submitting!</b> Warn your professor immediately and mention Dropbox.'.html_safe) and return
		end

		form_text = render_form_text(params[:a])

		#
		# upload everything to dropbox
		#
		if pset.form || pset.files
			begin
				upload_to_dropbox(session[:cas_user], current_user.name,
					Settings.dropbox_folder_name, folder_name, params[:notes], form_text, params[:f])
			rescue
				redirect_back(fallback_location: '/', alert: "<b>There was a problem uploading your submission! Please try again.</b> If the problem persists, contact your instructor.".html_safe ) and return
			end
		end

		#
		# create submit record
		#
		submit = Submit.where(:user_id => current_user.id, :pset_id => pset.id).first_or_initialize
		submit.submitted_at = Time.now
		submit.used_login = session[:cas_user]
		submit.url = params[:url]
		submit.folder_name = folder_name
		submit.check_feedback = nil
		submit.style_feedback = nil
		submit.auto_graded = false
		submit.submitted_files = params[:f].map { |file,info| info.original_filename } if params[:f]
		if files = params[:f]
			file_contents = {}
			files.each do |filename, file|
				name = file.original_filename
				if text_file?(name)
					if file.size < 60000
						file.rewind and file_contents[name] = file.read
					else
						file_contents[name] = "Uploaded file was too large!"
					end
				end
			end
		end
		submit.file_contents = file_contents
		submit.save
		
		#
		# create or touch submit for associated module, if possible/needed
		#
		if pset.parent_mod.present? && pset.parent_mod.pset.present?
			mod_submit = Submit.where(:user_id => current_user.id, :pset_id => pset.parent_mod.pset.id).first_or_initialize
			if mod_submit.persisted?
				mod_submit.touch(:submitted_at)
			else
				mod_submit.submitted_at = Time.now
				mod_submit.save
			end
		end
		
		#
		# get files to check server
		#
		if pset.config['check'] && files = params[:f]
			submitted_zips = files.keys.select { |x| x.end_with?(".zip") }
			if submitted_zips.any?
				zipfile = files[submitted_zips[0]]
				zipfile.rewind
			else
				zipfile = Zip::OutputStream.write_buffer(::LUploadIO.new('file.zip')) do |zio|
					files.each do |filename, file|
						zio.put_next_entry(filename)
						file.rewind
						zio.write file.read
					end
				end
				zipfile.rewind
			end

			server = RestClient::Resource.new(
			  "https://agile008.science.uva.nl/#{pset.config['check']['tool']}",
			  :verify_ssl       =>  OpenSSL::SSL::VERIFY_NONE
			)
		
			begin
				args = {
					file: zipfile,
					password: "martijndoeteenphd",
					webhook: "https://#{request.host}/check_result/do",
					multipart: true
					# and add slug/repo/args from the config file
				}.merge(pset.config['check'].slice('slug', 'repo', 'args'))
				response = server.post(args)
				logger.debug JSON.parse(response.body)['id']
				logger.debug submit.inspect
				submit.check_token = JSON.parse(response.body)['id']
				submit.save
			rescue RestClient::ExceptionWithResponse => e
			     logger.debug e.response
			end
			
		end
		
		#
		# this is a re-submit, so re-open for grading
		#
		if submit.grade
			submit.grade.grade = nil
			submit.grade.unfinished!
		end

		#
		# success, get back to previous page
		#
		begin
			redirect_back fallback_location: '/'
		rescue ActionController::RedirectBackError
			redirect_to :root
		end
	end
	
	private
	
	def text_file?(name)
		return [".py", ".c", ".txt", ".html", ".css", ".h", ".java"].include?(File.extname(name)) || name == "Makefile"
	end
	
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
		dropbox_root = "Submit"
		
		# cache timestamp for folder name
		item_folder = item

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
