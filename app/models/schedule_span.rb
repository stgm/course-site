class ScheduleSpan < ApplicationRecord

	belongs_to :schedule
	
	def content
		return YAML.load(self[:content])
	end
	
	def previous
		schedule.schedule_spans.where("id < ?", self.id).last || self
	end
	
	def next
		schedule.schedule_spans.where("id > ?", self.id).first || self
	end

end
