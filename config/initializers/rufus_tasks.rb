scheduler = Rufus::Scheduler.new

# If you want to change the mailing frequency, note that this frequency is
# present in two places in this code. One for running the scheduler regularly,
# and one for making sure only grades of a certain age are emailed, to allow
# for corrections within that timeframe.

scheduler.every '15m' do
	if Settings['mail_address']
		Grade.where("grades.mailed_at is not null").where(status: :published).joins([:submit]).find_each do |g|
			g.touch(:mailed_at)
			GradeMailer.new_mail(g).deliver
		end
	end
end
