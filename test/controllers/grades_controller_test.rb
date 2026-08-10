require "test_helper"

class GradesControllerTest < ActionController::TestCase

    tests GradesController

    setup do
        @schedule = Schedule.create!(name: "Test schedule")
        @pset = Pset.create!(name: "final", final: true, config: { "type" => "pass" })

        @admin = users(:test_user)
        @admin.update!(role: :admin, schedule: @schedule)

        @student = users(:test_user_2)
        @student.update!(role: :student, student_number: "12345678", status: :active, schedule: @schedule)

        @submit = @student.submits.create!(pset: @pset)
        @grade = @submit.create_grade!(grader: @admin)
        @grade.update!(status: :exported, exported_at: Time.current, grade: -1)
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    test "undo_export reverts a grade to pending" do
        sign_in(@admin)
        patch :undo_export, params: { id: @grade.id }

        @grade.reload
        assert @grade.published?
        assert_nil @grade.exported_at
    end

end
