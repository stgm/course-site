namespace :dev do
    desc "Seed the development database with a schedule, a grader, students and the example test psets"
    task seed: :environment do
        # Loading a course repo overwrites Settings.grading wholesale, which drops
        # the grading entries created below. Re-run this task after importing a course.
        abort "dev:seed only runs in development" unless Rails.env.development?

        # One pset per corner of the grade entry grid at /tests/:id/results, so
        # that the whole thing can be tried by hand after a change.
        example_tests = {
            # the plain case: a handful of parts and an ordinary formula
            "arrow-nav-test" => {
                "note" => "plain grid, normal modal width",
                "type" => "points",
                "subgrades" => {
                    "part_a" => "integer",
                    "part_b" => "integer",
                    "part_c" => "float",
                    "bonus" => "integer"
                },
                "calculation" => "part_a + part_b + part_c + bonus"
            },
            # more than six parts, so the modal goes wide; the names cover every
            # shape subgrade_header takes -- V1, V1B, X11, D.A, V.V.D.K -- plus
            # a single long word, which has no parts to shorten and so is the
            # one that ends up cut off
            "wide-test" => {
                "note" => "wide modal, shortened and ellipsised headers",
                "type" => "float",
                "subgrades" => {
                    "vraag_1" => "integer",
                    "vraag_2" => "integer",
                    "vraag_3" => "integer",
                    "vraag_1_bonus" => "integer",
                    "xx11" => "integer",
                    "deel_a" => "integer",
                    "opzet" => "integer",
                    "documentatiekwaliteit" => "integer",
                    "verantwoording_van_de_keuzes" => "integer"
                },
                # deliberately not every part: this one is about the layout
                "calculation" => "(vraag_1 + vraag_2 + vraag_3) / 3.0"
            },
            # sum_all: the Sum column, blank until every part has a value
            "sum-test" => {
                "note" => "sum_all, with a Sum column",
                "type" => "float",
                "subgrades" => {
                    "deel_a" => "integer",
                    "deel_b" => "integer",
                    "deel_c" => "integer"
                },
                "calculation" => "(sum_all / 15 * 9 + 1).round(1)"
            },
            # count_all: the Count column, which keeps counting while parts are
            # still blank
            "count-test" => {
                "note" => "count_all, with a Count column",
                "type" => "pass",
                "subgrades" => {
                    "vraag_1" => "pass",
                    "vraag_2" => "pass",
                    "vraag_3" => "pass",
                    "vraag_4" => "pass"
                },
                "calculation" => "(count_all >= 3) && -1 || 0"
            }
        }

        students = {
            "alice@example.test" => "Alice Anderson",
            "bob@example.test" => "Bob Bakker",
            "carla@example.test" => "Carla Cruz",
            "dirk@example.test" => "Dirk Dekker"
        }
        # enough more to make the list scroll, which is what the grid restores
        # after a save
        (1..26).each { |n| students["student#{n}@example.test"] = "Student Number#{n}" }

        # self_register makes this the default schedule
        schedule = Schedule.where(name: "Development").first_or_create!(self_register: true)
        puts "Schedule: #{schedule.name}"

        group = Group.where(name: "Development Group", schedule: schedule).first_or_create!
        puts "Group: #{group.name}"

        # /syllabus resolves to the schedule's page, and without one there is no
        # page to log in to and no menu to reach the tests from
        page = Page.where(slug: "development").first_or_initialize
        page.update!(title: "Development", path: "development", position: 1, public: true)
        schedule.update!(page: page) if schedule.page.blank?

        # a grader sees exactly the students of the groups assigned to them
        grader = User.where(mail: "grader@example.test").first_or_initialize
        grader.update!(name: "Gerda Grader", role: :head, schedule: schedule)
        group.graders << grader unless group.graders.include?(grader)
        puts "Grader: #{grader.name} <#{grader.mail}>"

        students.each do |mail, name|
            student = User.where(mail: mail).first_or_initialize
            student.update!(name: name, role: :student, schedule: schedule)
            # the group goes in a second save on purpose: User::Schedulizable
            # clears it again whenever the schedule changes
            student.update!(group: group)
        end
        puts "Students: #{group.users.student.count}"

        # grading config lives in the settings table, keyed on the pset name
        grading = Settings.grading || {}
        grading["grades"] ||= {}
        example_tests.each do |name, entry|
            grading["grades"][name] = entry.except("note").merge("is_test" => true)
        end
        GradingConfig.load grading

        # without this the Tests menu item stays hidden for a head
        Settings.tests_present = true

        puts
        puts "Log in as #{grader.mail}, then Menu > Tests..."
        example_tests.each_with_index do |(name, entry), i|
            pset = Pset.where(name: name).first_or_create!(order: 900 + i)
            puts "  /tests/#{pset.id}/results".ljust(24) + "#{name} -- #{entry['note']}"
        end
    end
end
