scheduler = Rufus::Scheduler.new

# If you want to change the mailing frequency, note that this frequency is
# present in two places in this code. One for running the scheduler regularly,
# and one for making sure only grades of a certain age are emailed, to allow
# for corrections within that timeframe.

scheduler.every '15m' do
	if Settings['mail_address']
		Grade.where("grades.mailed_at is null").where(status: Grade.statuses["published"]).joins([:submit]).find_each do |g|
			GradeMailer.new_mail(g).deliver
			g.touch(:mailed_at)
		end
	end
end

scheduler.every '3h' do
	User.all.each do |u|
		user_attendance = []
		for i in 0..6
			d_start = Date.today + 1 - 1 - i # start of tomorrow
			d_end = Date.today + 1 - i # start of today
			hours = u.attendance_records.where("cutoff >= ? and cutoff < ?", d_start, d_end).count
			user_attendance.insert 0, hours
		end
		# user_attendance.append u.attendance_records.count
		u.update_attribute(:attendance, user_attendance.join(","))
	end
end

scheduler.every '2h' do
	User.all.each do |u|
		u.update_attribute(:questions_count_cache, u.hands.count)
	end
end
