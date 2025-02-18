module Grade::Properties

    extend ActiveSupport::Concern

    included do
        enum :status, { unfinished: 0, finished: 1, published: 2, discussed: 3, exported: 4 }
        before_save :unpublicize_if_no_grade
    end

    def sortable_date
        updated_at
    end

    def public?
        published? or discussed? or exported?
    end

    def last_graded
        updated_at && updated_at.to_formatted_s(:short) || "not yet"
    end

    def first_graded
        created_at && created_at.to_formatted_s(:short) || "not yet"
    end

    private

    def unpublicize_if_no_grade
        self.status = Grade.statuses[:unfinished] if self.assigned_grade.blank?
        true
    end

end
