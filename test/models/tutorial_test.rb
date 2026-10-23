require "test_helper"

class TutorialTest < ActiveSupport::TestCase

    setup do
        @teacher = users(:test_user_2)
        @teacher.update!(role: :head)
        @student = users(:test_user)
        @student.update!(role: :student, student_number: "12345678", status: :active)

        @practice = Exam.create!(pset: psets(:mario), locked: true, kind: :practice, config: {})
        @real = Exam.create!(pset: psets(:goldbach), locked: true, config: {})

        Settings.registration_phase = "during"
    end

    teardown do
        Settings.registration_phase = "before"
        Settings.exam_current = nil
    end

    test "a new tutorial gets a 4-digit PIN" do
        tutorial = Tutorial.create!(exam: @practice, owner: @teacher)
        assert_match(/\A\d{4}\z/, tutorial.pin)
    end

    test "PINs are unique" do
        first = Tutorial.create!(exam: @practice, owner: @teacher)
        duplicate = Tutorial.new(exam: @practice, owner: @teacher, pin: first.pin)
        assert_not duplicate.valid?
    end

    test "only practice exams can have a tutorial" do
        assert_not Tutorial.new(exam: @real, owner: @teacher).valid?
    end

    test "a locked practice exam is closed without a membership" do
        assert_not @practice.open_for_user?(@student)
    end

    test "a membership opens a locked practice exam, also after the tutorial closes" do
        tutorial = Tutorial.create!(exam: @practice, owner: @teacher, open: true)
        TutorialMembership.create!(tutorial: tutorial, user: @student)
        assert Exam.find(@practice.id).open_for_user?(@student)

        tutorial.update!(open: false)
        assert Exam.find(@practice.id).open_for_user?(@student)
    end

    test "a membership does nothing in exam mode" do
        tutorial = Tutorial.create!(exam: @practice, owner: @teacher, open: true)
        TutorialMembership.create!(tutorial: tutorial, user: @student)

        Settings.registration_phase = "exam"
        assert_not Exam.find(@practice.id).open_for_user?(@student)
    end

    test "a locked submit still blocks a member" do
        tutorial = Tutorial.create!(exam: @practice, owner: @teacher, open: true)
        TutorialMembership.create!(tutorial: tutorial, user: @student)
        submits(:points_one).update!(locked: true) # test_user on the mario pset

        assert_not Exam.find(@practice.id).open_for_user?(@student)
    end

    test "the exam kind comes from type or from exam: true" do
        pset = psets(:mario)
        pset.update!(config: { "type" => "practice" })
        assert_equal "practice", Course::Tools.exam_kind(pset)

        pset.update!(config: { "exam" => true })
        assert_equal "exam", Course::Tools.exam_kind(pset)

        pset.update!(config: { "type" => "exam" })
        assert_equal "exam", Course::Tools.exam_kind(pset)

        pset.update!(config: { "type" => "bogus" })
        assert_nil Course::Tools.exam_kind(pset)

        pset.update!(config: {})
        assert_nil Course::Tools.exam_kind(pset)
    end

    test "register_exam stores the kind" do
        pset = psets(:mario)
        pset.update!(config: { "type" => "practice" })
        Course::Tools.register_exam(pset)
        assert Exam.find_by(pset: pset).practice?
    end

end
