class Hand < ApplicationRecord

    belongs_to :user, touch: true
    after_save :update_hands_count

    belongs_to :assist, class_name: "User", optional: true
    delegate :name, to: :assist, prefix: true, allow_nil: true

    scope :waiting, -> { where(assist_id: nil).where.not(done: true) }
    scope :successfully_helped, -> { where(success: true) }
    scope :total_duration, -> { sum("(JulianDay(closed_at) - JulianDay(claimed_at)) * 60 * 24").round }

    after_validation do |hand|
        if hand.done
            hand.user.update_attribute(:last_spoken_at, DateTime.now)
        end
        if hand.success
            # when using hands, assume that student is attending (true)
            hand.user.confirm_location!
        end
    end

    after_save do |hand|
        hand.user.notes.create(
            text: "Hand #{hand.id} -> #{hand.previous_changes.map { |k, v| [ k, v[1] ] }}",
            author: hand.user,
            log: true
        )
    end

    def self.remove_all_stale
        Hand.waiting.update_all done: true,
            evaluation: "Stale question removed from queue at night",
            closed_at: DateTime.current
    end

    def user_last_seen
        if attend = self.user.attendance_records.order("cutoff desc").first
            attend.cutoff
        else
            nil
        end
    end

    def sortable_date
        updated_at
    end

    def duration
        closed_at.present? ? ((closed_at - claimed_at)/60.0).round : 0
    end

    private

    def update_hands_count
        if success_previously_changed? || (previously_new_record? && success)
            if success
                user.increment! :hands_count
                user.increment! :hands_duration_count, duration
            else
                user.decrement! :hands_count
                user.decrement! :hands_duration_count, duration
            end
        end
    end

end
