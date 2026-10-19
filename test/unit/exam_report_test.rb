require "test_helper"

class ExamReportTest < ActiveSupport::TestCase

    setup do
        @exam = Exam.create!(pset: psets(:mario), locked: true, config: {})
        @exam.room = { "rows" => 8, "cols" => 16, "disabled" => [ "3-5", "1-1" ] }
        @exam.save!

        @a = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "2-3", submitted_at: 2.hours.ago)
        @b = Submit.create!(user: users(:test_user_2), pset: @exam.pset, seat: "6-14", submitted_at: 1.hour.ago)
    end

    test "empty rows and columns at the edges are cut off" do
        bounds = ExamReport.new(@exam).bounds

        assert_equal 2..6, bounds[:rows]
        assert_equal 3..14, bounds[:cols]
    end

    test "a wide room is drawn in landscape" do
        assert_equal :landscape, ExamReport.new(@exam).orientation
    end

    test "a tall narrow room is drawn in portrait" do
        @a.update!(seat: "1-1")
        @b.update!(seat: "8-2")

        assert_equal :portrait, ExamReport.new(@exam).orientation
    end

    test "renders a pdf" do
        assert ExamReport.new(@exam).render.start_with?("%PDF")
    end

    test "a normal room fits on a single page" do
        assert_equal 1, page_count(ExamReport.new(@exam).render)
    end

    test "a room so crowded that names get too small adds a list of names" do
        @exam.room = { "rows" => 40, "cols" => 40 }
        @exam.save!
        @a.update!(seat: "1-1")
        @b.update!(seat: "40-40")
        (2..39).each do |n|
            user = User.create!(name: "Student Met Een Hele Lange Achternaam #{n}", mail: "crowd#{n}@example.com")
            Submit.create!(user: user, pset: @exam.pset, seat: "#{n}-#{n}", submitted_at: 1.hour.ago)
        end

        assert_operator page_count(ExamReport.new(@exam).render), :>, 1
    end

    def page_count(pdf)
        pdf.scan(%r{/Type /Page(?!s)}).size
    end

end
