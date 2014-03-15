scheduler = Rufus::Scheduler.new

# If you want to change the mailing frequency, note that this frequency is
# present in two places in this code. One for running the scheduler regularly,
# and one for making sure only grades of a certain age are emailed, to allow
# for corrections within that timeframe.

scheduler.every '1h' do
	if Settings.send_grade_mails
		Grade.where("updated_at < ? and mailed_at < updated_at and grade is not null", 2.hours.ago).find_each do |g|
			GradeMailer.new_mail(g).deliver
			g.touch(:mailed_at)
		end
	end
end
