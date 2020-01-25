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
		@xtra = user.submits.includes({:pset => [:parent_mod, :mod]}).where("submitted_at is not null").where("psets.mod_id is not null or mods_psets.pset_id is null").references(:psets, :mods).to_a.group_by_day{|i| i.created_at}
		# @xtra.each { |k,v| puts k; puts v }
		# puts "---"
		
		
		@grouped_items.merge!(@xtra) { |k,v1,v2| puts k; puts v1; puts v2; v1 + v2 }
		# puts @grouped_items
		# @grouped_items.each { |k,v| puts k; puts v }
		
		tag.div class: "blockgraph #{args} #{args[:class]}" do
			@attendance = user.attendance_by_day
			@attendance.default = 0
			course_dates.each do |date|
				@day_items = @grouped_items.select{|k,v| k==date}.collect{|k,v| v.collect{|ai| ai.short_description}}.flatten
				concat tag.div((@day_items.join =~ /submit/ && 's' || ''), class: "block strength-#{[@attendance[date],8].min} #{@day_items.any? && 'interesting' || ''} #{!(1..5).include?(date.wday) && 'weekend' ||  ''}", data: { toggle: 'tooltip', placement: 'top' }, title: "#{date} (#{@attendance[date]}) #{@day_items}")
			end
		end
	end
	
end
