unless self.private_methods.include? 'irb_binding'

	def safely
		begin
			unless ActiveRecord::Base.connected?
				ActiveRecord::Base.connection.verify!(0)
			end
			yield
		rescue => e
			status e.inspect
		ensure
			ActiveRecord::Base.connection_pool.release_connection
		end
	end
		
	scheduler = Rufus::Scheduler.new

	unless (defined?(Rails::Console) || File.split($0).last == 'rake')

		# If you want to change the mailing frequency, note that this frequency is
		# present in two places in this code. One for running the scheduler regularly,
		# and one for making sure only grades of a certain age are emailed, to allow
		# for corrections within that timeframe.

		scheduler.every '55m' do
			if Settings.send_grade_mails && Settings.mailer_from.present?
				Grade.where("grades.mailed_at is null").published.joins([:submit]).find_each do |g|
					GradeMailer.new_mail(g).deliver
					ActiveRecord::Base.transaction do
						g.touch(:mailed_at)
					end
				end
			end
		end
	
		scheduler.cron '00 06 * * *' do
			safely do
			    ActiveRecord::Base.transaction do
					User.all.each &:update_last_submitted_at
				end
			end
		end
	
		# scheduler.every '20m' do
		# 	if Settings.automatic_grading_enabled
		# 		Submit.where(check_feedback: nil).limit(20).each do |s|
		# 			sleep 1
		# 			s.retrieve_check_feedback
		# 		end
		# 		Submit.where(check_feedback: nil).limit(20).each do |s|
		# 			sleep 1
		# 			s.retrieve_style_feedback
		# 		end
		# 	end
		# end

		scheduler.every '135m' do
			safely do
			    ActiveRecord::Base.transaction do
					User.all.each do |u|
						u.take_attendance
					end
				end
			end
		end

		scheduler.cron '30 06 * * *' do
			safely do
			    ActiveRecord::Base.transaction do
					User.all.each do |u|
						u.update_attribute(:questions_count_cache, u.hands.count)
					end
				end
			end
		end
	
		scheduler.cron '00 05 * * *' do
			safely do
			    ActiveRecord::Base.transaction do
					# reset locations
					User.update_all(last_known_location: nil)
					# reset hands that were never released
					Hand.where("updated_at < ?", Date.today).where(done: false).update_all(done: true)
				end
			end
		end

	end
	
end
