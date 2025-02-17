module User::Staffable
    extend ActiveSupport::Concern

    included do
        enum :role, { guest: 0, student: 1, assistant: 2, head: 3, admin: 4 }, default: :student

        # permissions for heads/tas
        has_and_belongs_to_many :groups
        has_and_belongs_to_many :schedules
        has_many :students, through: :groups

        has_many :authored_grades, class_name: "Grade", foreign_key: "grader_id"
        has_many :authored_notes, class_name: "Note", foreign_key: "author_id"

        scope :staff, -> { where(role: [:admin, :assistant, :head]) }
        scope :not_staff, -> { where.not(role: [:admin, :assistant, :head]) }
    end

    def staff?
        admin? or assistant? or head?
    end

    def senior?
        admin? or head?
    end

    def accessible_schedules
        if self.admin?
            # ensure admins have access to all schedules at all times by overriding
            Schedule.all
        else
            self.schedules
        end
    end
end
