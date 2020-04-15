module AutoCheck::Receiver
	
	extend ActiveSupport::Concern

	def register_auto_check_results(json)
		# save the raw results
		self.check_token = nil
		self.check_results = json
		
		if self.pset.config['auto_publish']
			# create a create if needed
			grade = self.grade || self.build_grade
		
			# overwrite previous automatic scores
			self.automatic_scores.each do |k,v|
				grade.subgrades[k] = v
			end

			# immediately try calculating the grade and publishing
			grade.set_calculated_grade
			grade.status = Grade.statuses[:published]
			grade.grader = User.admin.first
			grade.save
		
			# if the results do not appear OK, send an e-mail
			if grade.calculated_grade == 0
				GradeMailer.bad_submit(self).deliver
			end
		end

		self.save
	end
	
end
