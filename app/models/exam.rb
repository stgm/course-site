class Exam < ApplicationRecord

    belongs_to :pset
    delegate :name, to: :pset

    serialize :config, coder: YAML, type: Hash

    def allow_taking?
        # in exam mode, only show "current" exams
        (Settings.registration_phase == "exam" && self.current_exam) ||
        # outside of exam mode, only show unlocked exams (e.g. practice)
        (Settings.registration_phase != "exam" && !self.locked?)
    end
end
