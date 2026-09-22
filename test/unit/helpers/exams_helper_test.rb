require "test_helper"

class ExamsHelperTest < ActionView::TestCase

    include ExamsHelper

    setup do
        @submit = Submit.create!(user: users(:test_user), pset: psets(:mario), submitted_at: Time.current)
    end

    test "freshness follows how long ago the editor last posted" do
        @submit.update!(submitted_at: 30.seconds.ago)
        assert_equal "warm", exam_freshness(@submit)

        @submit.update!(submitted_at: 5.minutes.ago)
        assert_equal "cool", exam_freshness(@submit)

        @submit.update!(submitted_at: 40.minutes.ago)
        assert_equal "cold", exam_freshness(@submit)

        @submit.update!(submitted_at: nil)
        assert_equal "cold", exam_freshness(@submit)
    end

    test "a locked student is not warned about, however long they have been quiet" do
        @submit.update!(locked: true, submitted_at: 3.hours.ago)
        assert_equal "locked-out", exam_freshness(@submit)

        @submit.update!(submitted_at: 10.seconds.ago)
        assert_equal "locked-out", exam_freshness(@submit),
            "being locked says more about the table than a fresh postback does"
    end

    test "a first name is only spelled out further when two students share it" do
        assert_equal "Test", exam_seat_name(@submit, [])
        assert_equal "Test U.", exam_seat_name(@submit, [ "test" ])
    end

    test "ambiguous first names are the ones carried by more than one student" do
        other = Submit.create!(user: User.create!(name: "Test Tweede", mail: "t2@example.com"), pset: psets(:mario))
        alone = Submit.create!(user: User.create!(name: "Sam Derde", mail: "t3@example.com"), pset: psets(:mario))

        assert_equal [ "test" ], exam_ambiguous_first_names([ @submit, other, alone ])
    end

end
