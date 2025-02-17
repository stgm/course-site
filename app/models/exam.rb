class Exam < ApplicationRecord

    belongs_to :pset
    delegate :name, to: :pset

    serialize :config, coder: YAML, type: Hash

    def allow_taking?
        (Settings.registration_phase == 'exam' && self.current_exam) ||
        (Settings.registration_phase != 'exam' && !self.locked?)
    end
end
