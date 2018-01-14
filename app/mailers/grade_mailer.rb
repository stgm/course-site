class GradeMailer < ActionMailer::Base

	helper GradesHelper

	default from: Settings['mail_address']
	
	def new_mail(grade)
		@course_name = Settings.short_course_name
		@grade_name = grade.pset.name
		@feedback = grade.comments
		if Settings.grading && Settings.grading['grades'][grade.submit.pset.name] && !Settings.grading['grades'][grade.submit.pset.name]['hide_calculated']
			@grade = grade.any_final_grade
		else
			@grade = grade.grade
		end
		@login = grade.submit.used_login if grade.submit
		@header = File.read("#{Rails.root}/public/course/mail/grade.txt") if File.exists?("#{Rails.root}/public/course/mail/grade.txt")
		Rails.logger.debug ENV["MAILER_ADDRESS"]
		mail(to: grade.user.mail, subject: "#{Settings.short_course_name}: feedback for #{@grade_name}")
	end
	
end
