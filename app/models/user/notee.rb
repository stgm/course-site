module User::Notee
    extend ActiveSupport::Concern

    included do
        has_many :notes, foreign_key: "student_id" # with counter cache
    end
end
