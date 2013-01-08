class UploadController < ApplicationController
	
	# will break the submit if not logged in!
	before_filter RubyCAS::Filter
	
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
			logger.debug "HUH"
			logger.debug page.inspect
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
		
			dropbox.submit(current_user.uvanetid, current_user.name, Course.course['short'], pset.name, params[:notes], form_text, params[:f])

			# success
			redirect_to(:back, :notice => "<b>Thanks for submitting!</b> Everything was successfully uploaded.".html_safe)
		else			
			render :text => 'Dropbox is not linked, please warn your professor immediately.'
		end

	end
	
end
