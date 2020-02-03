module AutoCheck::Receiver
	
	extend ActiveSupport::Concern

	def register_auto_check_results(json)
		# put results into db
		self.check_token = nil
		self.check_results = json
		
		# create a create if needed
		grade = self.grade || self.build_grade
		
		# check via the grade if this submit is OK
		grade.set_calculated_grade
		grade.status = Grade.statuses[:published]
		grade.grader = User.admin.first
		grade.save
		
		self.save

		# if not OK, send an e-mail
		if grade.calculated_grade == 0
			GradeMailer.bad_submit(self).deliver
		end
	end
	
end
