class Exam < ApplicationRecord

    belongs_to :pset
    delegate :name, to: :pset

    serialize :config, coder: YAML, type: Hash

    def allow_taking?
        # in exam mode, only show "current" exams
        (Settings.registration_phase == "exam" && Settings.exam_current == self.id) ||
        # outside of exam mode, only show unlocked exams (e.g. practice)
        (Settings.registration_phase != "exam" && !self.locked?)
    end

    def open_for_user?(user)
        @open_for_user ||= {}
        @open_for_user[user.id] ||= begin
            submit = Submit.find_by(user: user, pset: pset)
            user.admin? || allow_taking? && (submit.nil? || !submit.locked?)
        end
    end

    def name_with_code
        if eval_code.present?
            "#{name.titleize} (#{eval_code})"
        else
            name.titleize
        end
    end
end
