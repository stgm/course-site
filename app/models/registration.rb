class Registration < ActiveRecord::Base

	belongs_to :user
	belongs_to :track
	
	belongs_to :schedule
	belongs_to :schedule_span

	attr_accessible :term, :status, :user, :track, :schedule_id, :schedule_span_id
	
	# ensure that if a schedule is selected, a valid schedule_span is also present
	before_save do |r|
		if r.schedule.present?
			if r.schedule_span.present?
				r.schedule_span = r.schedule.schedule_spans.first if not r.schedule.schedule_spans.include?(r.schedule_span)
			else
				r.schedule_span = r.schedule.schedule_spans.first
			end
		else
			r.schedule_span = nil
		end
	end

end
