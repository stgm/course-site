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
			redirect_to(:back, :notice => "Thanks for submitting! Make sure to ask your assistant for the results next week. NOTICE: Your upload will not immediately appear in the list on the right. No worries.")		
		else			
			render :text => 'Dropbox is not linked, please warn your professor immediately.'
		end

	end
	
end
