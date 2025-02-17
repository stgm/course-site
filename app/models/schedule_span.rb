class ScheduleSpan < ApplicationRecord

    belongs_to :schedule
    serialize :content, coder: YAML

    scope :all_public, -> { where('public = ? OR publish_at < ?', true, DateTime.now) }
    scope :accessible, -> { Current.user.staff? && all || all_public }

    def name
        if Current.user.staff?
            (self[:name] + " <div class='badge bg-secondary'>#{self.publish_at&.strftime('%d %b')}</div>").html_safe
        else
            self[:name]
        end
    end
    
    def accessible?
        public? || publish_at.present? && publish_at < DateTime.now
    end

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
