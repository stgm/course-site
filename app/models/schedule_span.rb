class ScheduleSpan < ApplicationRecord

	belongs_to :schedule
	serialize :content
	
	scope :all_public, -> { where(public: true) }
	scope :accessible, -> { Current.user.staff? && all || all_public }

	def previous(only_public=true)
		spans = schedule.schedule_spans
		spans = spans.all_public if only_public
		spans.where("rank < ?", self.rank).order(:rank).last
	end

	def next(only_public=true)
		spans = schedule.schedule_spans
		spans = spans.all_public if only_public
		spans.where("rank > ?", self.rank).order(:rank).first
	end

end
