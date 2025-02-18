module User::Submitter

    extend ActiveSupport::Concern

    included do
        has_many :submits
        has_many :grades, through: :submits
        has_many :psets, through: :submits

        scope :who_did_not_submit, ->(pset_id) do
            where("not exists (?)", Submit.where("submits.user_id = users.id").where(pset_id: pset_id))
        end
    end

    def submit(pset)
        submits.where(pset_id: pset.id).first
    end

    def can_submit?
        return self.valid_profile? && self.defacto_student_identifier.present?
        # TODO return reason
    end

    def all_submits
        self.grades.group_by { |i| i.submit.pset.name }.each_with_object({}) { |(k, v), o| o[k] = v[0] }
    end

    def final_grade
        "N/A"
    end

end
