class Submit < ActiveRecord::Base

	belongs_to :user
	delegate :name, to: :user, prefix: true, allow_nil: true

	belongs_to :pset
	delegate :name, to: :pset, prefix: true, allow_nil: true

	has_one :grade, dependent: :destroy
	delegate :status, to: :grade, prefix: true, allow_nil: true

	serialize :submitted_files
	serialize :check_feedback
	serialize :file_contents

	def graded?
		return (self.grade && (!self.grade.grade.blank? || !self.grade.calculated_grade.blank?))
	end
	
	def check_score
		self.check_feedback.count { |x| x["status"].present? } / self.check_feedback.size.to_f
	end
	
	def check_feedback_problems?
		return false if self.check_feedback.blank?
		
		self.check_feedback.index { |x| x["status"].blank? }.present?
	end
	
	def retrieve_feedback
		path = File.join(Dropbox.root_folder, Settings.dropbox_folder_name, user.login_id, self.folder_name, 'check_results.json')
		begin
			json = Dropbox.download(path)
			contents = json.present? ? JSON.parse(json) : nil
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
	
	def check_feedback_formatted
		return "" if self.check_feedback.blank?

		result = ""
		self.check_feedback.each do |item|
			case item["status"]
			when true
				result << ":)"
			when false
				result << ":("
			when nil
				result << ":|"
			end
			result << " " + item["description"] + "\n"
			if item["rationale"].present?
				result << "    " + item["rationale"] + "\n"
			end
		end
		
		return result
	end

end
