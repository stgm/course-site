scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
	Rails.logger.debug "Rufuuuuuus"
	if Settings.send_grade_mails
		Grade.where("updated_at < ? and mailed_at < updated_at and grade is not null", 1.minutes.ago).find_each do |g|
			GradeMailer.new_mail(g).deliver
			g.touch(:mailed_at)
		end
	end
end
