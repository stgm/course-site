class Grade < ApplicationRecord
    include Storage, SubGrades, Properties, Calculator, Formatter

    belongs_to :submit, touch: true

    has_one :user, through: :submit
    delegate :name, to: :user, prefix: true, allow_nil: true
    after_save :set_user_status_to_done_if_final_grade

    has_one :pset, through: :submit
    delegate :name, to: :pset, prefix: true, allow_nil: true
    delegate :config, to: :pset, allow_nil: true

    belongs_to :grader, class_name: "User"
    delegate :name, to: :grader, prefix: true, allow_nil: true
    delegate :initials, to: :grader, prefix: true, allow_nil: true
    before_validation :assign_grader_if_needed

    scope :showable, -> { where(status: [Grade.statuses[:published], Grade.statuses[:exported]]) }

    def sufficient?
        published? && (assigned_grade >= 5.5 || assigned_grade == -1)
    end

    def resubmit_exception?
        published? && assigned_grade == -2
    end

    def reject!
        self.grade = 0
        published!
    end

    def assigned_grade
        self.grade || self.calculated_grade
    end

    private

    def set_user_status_to_done_if_final_grade
        if sufficient? && pset.is_final_grade? && Current.user.present? && Current.user.admin?
            user.status_done!
        end
    end

    def assign_grader_if_needed
        if grader.blank? || (Current.user.present? && Current.user != grader && grader.senior?)
            self.grader = Current.user
        end
    end
end
