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

        # ensure last admin stays it!
        validate :last_admin_keeps_the_role
        before_destroy :refuse_to_destroy_last_admin

        # for site cleanup we can remove all non-admin staff in one go
        scope :revocable_staff, -> { where(role: [ :assistant, :head ]) }
        def self.revoke_staff_rights!
            transaction do
                revocable_staff.find_each do |user|
                    user.groups.clear
                    user.schedules.clear
                    user.update!(role: :guest)
                end
            end
        end
    end

    def staff?
        admin? or assistant? or head?
    end

    # the only admin left, so the one who may not lose the role
    def last_admin?
        admin? && persisted? && !User.admin.where.not(id: id).exists?
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

    private

    def last_admin_keeps_the_role
        # role_was represents current database
        return unless persisted? && role_was == "admin" && !admin?
        return if User.admin.where.not(id: id).exists?
        errors.add(:role, "cannot be taken away from the last admin")
    end

    def refuse_to_destroy_last_admin
        throw :abort if last_admin?
    end

end
