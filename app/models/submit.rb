class Submit < ActiveRecord::Base

	belongs_to :user
	belongs_to :pset

	has_one :grade, dependent: :destroy

	serialize :submitted_files

	def graded?
		return (self.grade && (!self.grade.grade.blank? || !self.grade.calculated_grade.blank?))
	end
	
	def retrieve_feedback
		path = File.join(Dropbox.root_folder, Settings.dropbox_folder_name, user.login_id, self.folder_name, 'check_feedback.json')
		begin
			contents = Dropbox.download(path)
			self.update(check_feedback: contents)
		rescue
			# go on, assuming its not there
		end

		# path = File.join(Dropbox.root_folder, Settings.dropbox_folder_name, user.login_id, self.folder_name, 'style_feedback.json')
		# begin
		# 	contents = Dropbox.download(path)
		# 	self.update(style_feedback: contents)
		# rescue
		# 	# done anyway, assuming its not there
		# end
	end

end
