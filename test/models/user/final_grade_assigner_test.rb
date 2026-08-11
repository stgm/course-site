require "test_helper"

class User::FinalGradeAssignerTest < ActiveSupport::TestCase

    # One registration off one exam attempt list, so that a second attempt changes the
    # resit grade and the assigner has something to write a note about.
    CONFIG = {
        "exams"       => { "type" => "pass_first", "submits" => [ "exam_1", "exam_2", "exam_3" ] },
        "exams_resit" => { "type" => "pass_last", "submits" => [ "exam_1", "exam_2", "exam_3" ] },
        "calculation" => {
            "sp1_final" => { "type" => "pass", "components" => [ "exams" ] },
            "sp1_resit" => { "type" => "pass", "components" => [ "exams_resit" ] }
        }
    }.freeze

    def setup
        Settings.grading = CONFIG.deep_dup
        @student = users(:test_user)
        @student.update!(role: :student, schedule: Schedule.create!(name: "Assign"))
        [ "exam_1", "exam_2", "exam_3", "sp1_final", "sp1_resit" ].each_with_index do |name, order|
            final = name.start_with?("sp1")
            Pset.create!(name: name, order: order, final: final,
                config: final ? { "type" => "pass" } : { "type" => "pass" })
        end
    end

    # a graded exam attempt, entered the way a grader would
    def attempt(name, value, graded_at = Time.current)
        submit = @student.submits.where(pset: Pset.find_by(name: name)).first_or_create!
        submit.create_grade!(grader: @student) if submit.grade.blank?
        submit.grade.update!(grade: value, status: :published)
        submit.grade.update_columns(updated_at: graded_at)
        submit.grade
    end

    def final_grade(name)
        @student.reload.all_submits[name]
    end

    # the grades association caches, and the attempts above are updated through their own
    # submits, so the student has to be read again for the calculation to see them
    def assign
        @student.reload.assign_final_grade(@student)
    end

    test "the resit note says which attempt was overwritten" do
        attempt("exam_1", 0)
        attempt("exam_2", 0, Date.new(2025, 12, 15).noon)
        assign

        # two attempts: the second one is the resit and has overwritten nothing
        assert_equal 0, final_grade("sp1_resit").assigned_grade
        assert_no_match(/overwritten/, final_grade("sp1_resit").notes)

        attempt("exam_3", -1, Date.new(2026, 3, 6).noon)
        assign

        resit = final_grade("sp1_resit")
        assert_equal(-1, resit.assigned_grade)
        assert_match "sp1_resit is now based on exam_3 (sufficient, graded 6 March 2026)", resit.notes
        assert_match "previous result from exam_2 (insufficient, graded 15 December 2025) was overwritten",
            resit.notes
    end

    test "an unchanged grade gains no notes" do
        attempt("exam_1", -1)
        assign
        before = final_grade("sp1_final").notes

        assign

        assert_equal before, final_grade("sp1_final").notes
    end

    test "a published final grade keeps its value and records what a recalculation gives" do
        attempt("exam_1", 0)
        attempt("exam_2", 0)
        assign

        resit = final_grade("sp1_resit")
        resit.published!
        resit.update_columns(updated_at: 1.week.ago, notes: nil)
        graded_at = resit.reload.updated_at

        # the student passes a later attempt, so the calculation no longer agrees
        attempt("exam_2", -1)
        assign

        resit = final_grade("sp1_resit")
        assert_equal 0, resit.assigned_grade, "a published grade is never overwritten"
        assert_match "not changed, because this grade is already published", resit.notes
        assert_match "A recalculation gives sufficient", resit.notes
        assert_equal graded_at.to_i, resit.updated_at.to_i,
            "annotating a published grade must not move its last graded time"
    end

end
