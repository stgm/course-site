unless self.private_methods.include? 'irb_binding'

	def safely
		begin
			unless ActiveRecord::Base.connected?
				ActiveRecord::Base.connection.verify!(0)
			end
			yield
		rescue => e
			puts e.inspect
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
			if GradeMailer.available?
				Grade.where("grades.mailed_at is null").published.where("grades.updated_at > ?", 1.day.ago).where("grades.updated_at < ?", 2.hours.ago).joins([:submit]).find_each do |g|
					if g.comments.present?
						GradeMailer.new_mail(g).deliver
						ActiveRecord::Base.transaction do
							g.touch(:mailed_at)
						end
					end
				end
			end
		end

		scheduler.every '135m' do
			safely do
				ActiveRecord::Base.transaction do
					User.all.each do |u|
						u.take_attendance
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
