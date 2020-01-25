module ProgressHelper
	
	def course_dates
		if Settings.course_start_date.present? and Settings.course_end_date.present?
			return Settings.course_start_date..Settings.course_end_date
		else
			return AttendanceRecord.order(:cutoff).first.cutoff.to_date..AttendanceRecord.order(:cutoff).last.cutoff.to_date
		end
	end
	
	def progress_bar(user, items, **args)
		@grouped_items = items.group_by_day{ |i| i.class==Submit && i.submitted_at || i.updated_at }
		tag.div class: "blockgraph #{args} #{args[:class]}" do
			@attendance = user.attendance_by_day
			@attendance.default = 0
			course_dates.each do |date|
				@day_items = @grouped_items.select{|k,v| k==date}.collect{|k,v| v.collect{|ai| ai.short_description}}.flatten
				concat tag.div(class: "block strength-#{[@attendance[date],8].min} #{@day_items.any? && 'interesting' || ''} #{!(1..5).include?(date.wday) && 'weekend' ||  ''}", data: { toggle: 'tooltip', placement: 'top' }, title: "#{date} (#{@attendance[date]}) #{@day_items}") do
					@day_items.join =~ /submit/ && 's' || ''
				end
			end
		end
	end
	
end