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
		logger.debug path
		# Dropbox.download()
	end

end
