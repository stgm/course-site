unless self.private_methods.include? 'irb_binding'
	scheduler = Rufus::Scheduler.new

	# If you want to change the mailing frequency, note that this frequency is
	# present in two places in this code. One for running the scheduler regularly,
	# and one for making sure only grades of a certain age are emailed, to allow
	# for corrections within that timeframe.

	scheduler.every '15m' do
		if Settings.send_grade_mails && Settings['mail_address']
			Grade.where("grades.mailed_at is null").where(status: Grade.statuses["published"]).joins([:submit]).find_each do |g|
				GradeMailer.new_mail(g).deliver
				g.touch(:mailed_at)
			end
		end
	end
	
	scheduler.every '10m' do
		User.all.each &:update_last_submitted_at
	end
	
	scheduler.every '20m' do
		if Settings.automatic_grading_enabled
			Submit.where(check_feedback: nil).limit(10).each &:retrieve_feedback
		end
	end

	# //attendance_records.group_by_day(:cutoff, default_value: 0).count
	scheduler.every '1h' do
		User.all.each do |u|
			u.take_attendance
		end
	end

	scheduler.every '2h' do
		User.all.each do |u|
			u.update_attribute(:questions_count_cache, u.hands.count)
		end
	end
	
	scheduler.cron '00 05 * * *' do
		User.update_all(last_known_location: nil)
	end
end
