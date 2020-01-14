module AutoCheckReceiver
	
	extend ActiveSupport::Concern

	def register_auto_check_results(json)
		# put results into db
		self.check_token = nil
		self.check_results = json
		
		# create a create if needed
		grade = self.grade || self.build_grade
		
		# check via the grade if this submit is OK
		self.automatic_scores.each do |k,v|
			grade.subgrades[k] = v
		end
		grade.set_calculated_grade
		grade.status = Grade.statuses[:published]
		grade.save
		
		self.save

		# if not OK, send an e-mail
		if grade.calculated_grade == 0
			GradeMailer.bad_submit(self).deliver
		end
	end
	
end
