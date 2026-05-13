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

        scope :staff, -> { where(role: [ :admin, :assistant, :head ]) }
        scope :not_staff, -> { where.not(role: [ :admin, :assistant, :head ]) }
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

    def accessible_groups
        self.groups
    end

    # Returns an AR relation of non-staff users visible to this staff member.
    #
    # Rule (per schedule):
    #   - Schedule assigned, no groups from that schedule → all students in that schedule
    #   - Schedule assigned, groups from that schedule → only those groups
    #   - Group assigned, no schedule assigned → only that group
    #   - Admin → everyone
    #   - Nothing assigned → nobody
    def accessible_students
        return User.all   if admin?
        return User.none  if schedules.none? && groups.none?

        # Schedules where I have no specific group → full-schedule access
        schedules_without_my_groups = schedules.where.not(id: groups.select(:schedule_id))

        scopes = [
            (User.not_staff.where(group: groups)                         if groups.any?),
            (User.not_staff.where(schedule: schedules_without_my_groups) if schedules_without_my_groups.any?)
        ].compact

        scopes.any? ? scopes.reduce { |combined, s| combined.or(s) } : User.none
    end

end
