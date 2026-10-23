class Tutorial < ApplicationRecord

    belongs_to :exam
    belongs_to :owner, class_name: "User", foreign_key: :user_id
    belongs_to :schedule, optional: true
    has_many :memberships, class_name: "TutorialMembership", dependent: :destroy
    has_many :users, through: :memberships

    validates :pin, presence: true, uniqueness: true
    validate :exam_is_practice

    before_validation :generate_pin, on: :create

    delegate :name, to: :exam

    # Tells whether this user is allowed to claim the code: only students from the
    # schedule the code was made for. Starting the exam later is not checked.
    def claimable_by?(user)
        schedule_id.nil? || user.schedule_id == schedule_id
    end

    # Names the first boolean subgrade of the exam's pset for this student, such as
    # "meegedaan". The grading config is per schedule, so it is read through the
    # student's own schedule. Returns nil if the pset has no boolean subgrade.
    def attendance_subgrade(user)
        subgrades = user.grading_config.grades.dig(exam.pset.name, "subgrades") || {}
        subgrades.find { |_name, type| type == "boolean" }&.first
    end

    # Tells how many automatic checks of a submit passed: "3 of 5", "running" while
    # the check server is working, or nil if the submit was never checked.
    def check_summary(submit)
        return nil if submit.nil?
        return :running if submit.check_token.present?

        summary = submit.check_results.try(:dig, "summary")
        return nil unless summary.is_a?(Hash) && summary["total_check_count"]

        I18n.t("tutorial.checks", passed: summary["passed_check_count"].to_i, total: summary["total_check_count"])
    end

    private

    # Picks a random 4-digit PIN that no other tutorial uses.
    def generate_pin
        return if pin.present?
        self.pin = loop do
            candidate = format("%04d", SecureRandom.random_number(10_000))
            break candidate unless Tutorial.exists?(pin: candidate)
        end
    end

    def exam_is_practice
        errors.add(:exam, "must be a practice exam") unless exam&.practice?
    end

end
