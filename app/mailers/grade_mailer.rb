class GradeMailer < ActionMailer::Base

	helper GradesHelper

	default from: Settings['mail_address']
	
	def new_mail(grade)
		@course_name = Settings.short_course_name
		@grade_name = grade.pset.name
		@feedback = grade.comments
		@grade = grade.grade
		Rails.logger.info ENV["MAILER_ADDRESS"]
		mail(to: grade.user.mail, subject: "Feedback for #{Settings.short_course_name}")
	end
	
end
