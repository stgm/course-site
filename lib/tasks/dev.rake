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

    desc "Load the SP course from a local checkout and seed students covering every pass/fail case"
    task sp_seed: :environment do
        abort "dev:sp_seed only runs in development" unless Rails.env.development?

        repo = ENV["COURSE_REPO"] || File.expand_path("~/dev/spcourse/website")
        branch = ENV["COURSE_BRANCH"] || "2026"
        schedule_name = ENV["SCHEDULE"] || "SP S1"
        registrations = [ "sp1_final", "sp1_resit" ]

        # the four exam sittings, so that the dates in an overwrite note can be checked
        exam_dates = {
            "sp1_exam1" => Date.new(2025, 10, 20),
            "sp1_exam2" => Date.new(2025, 12, 15),
            "sp1_exam3" => Date.new(2026, 3, 6),
            "sp1_exam4" => Date.new(2026, 6, 29)
        }
        checks = { "m1_passed" => -1, "m2_passed" => -1, "m3_passed" => -1 }

        # Every student's expected pair of registrations, so that the task itself says
        # whether the calculation still does what it is supposed to do. A grade of -1 is a
        # pass, 0 a fail, and nil means no grade can be registered yet.
        students = {
            "pass@example.test" => [ "Paula Pass", [ -1, nil ],
                checks.merge("sp1_exam1" => -1) ],
            "failedexam@example.test" => [ "Frits Failedexam", [ 0, nil ],
                checks.merge("sp1_exam1" => 0) ],
            "resitpass@example.test" => [ "Rita Resitpass", [ 0, -1 ],
                checks.merge("sp1_exam1" => 0, "sp1_exam2" => -1) ],
            "resitfail@example.test" => [ "Rudi Resitfail", [ 0, 0 ],
                checks.merge("sp1_exam1" => 0, "sp1_exam2" => 0) ],
            "thirdtime@example.test" => [ "Tess Thirdtime", [ 0, -1 ],
                checks.merge("sp1_exam1" => 0, "sp1_exam2" => 0, "sp1_exam3" => -1) ],
            "noexam@example.test" => [ "Nora Noexam", [ nil, nil ],
                checks ],
            "failedcheck@example.test" => [ "Ferdi Failedcheck", [ 0, nil ],
                checks.merge("m2_passed" => 0, "sp1_exam1" => -1) ],
            "nocheck@example.test" => [ "Nina Nocheck", [ nil, nil ],
                checks.merge("m2_passed" => 0) ],
            "halfway@example.test" => [ "Hilde Halfway", [ nil, nil ],
                checks.except("m3_passed").merge("sp1_exam1" => -1) ]
        }

        # a local path is a valid git remote, so the course does not have to be pushed;
        # note that Course::Git diffs against HEAD, so commit before running this
        Settings.git_repo = repo
        Settings.git_branch = branch
        puts "Course: #{repo} @ #{branch}"

        errors = Course::Loader.new.run
        errors.each { |error| puts "! #{error}" }
        puts

        schedule = Schedule.find_by(name: schedule_name)
        abort "No schedule named #{schedule_name}; the course repo did not load" if schedule.blank?
        schedule.update!(self_register: true)
        group = Group.where(name: "SP Group", schedule: schedule).first_or_create!
        puts "Schedule: #{schedule.name}, group: #{group.name}"

        # grades need a grader, and only an admin may calculate final grades
        admin = User.where(mail: "admin@example.test").first_or_initialize
        admin.update!(name: "Ada Admin", role: :admin, schedule: schedule)
        Current.user = admin
        puts "Admin: #{admin.name} <#{admin.mail}>"
        puts

        students.each do |mail, (name, _expected, grades)|
            student = User.where(mail: mail).first_or_initialize
            student.update!(name: name, role: :student, schedule: schedule)
            # the group goes in a second save on purpose: User::Schedulizable
            # clears it again whenever the schedule changes
            student.update!(group: group)

            grades.each do |pset_name, value|
                pset = Pset.find_by(name: pset_name)
                raise "no pset #{pset_name}" if pset.blank?

                submit = student.submits.where(pset: pset).first_or_create!
                submit.create_grade if submit.grade.blank?
                # the grade follows from the subgrades, exactly as a grader would enter them
                submit.grade.subgrades = { "passed" => value }
                submit.grade.grader = admin
                submit.grade.status = :published
                submit.grade.save!

                # an exam was graded on the day it was sat, which is what the note about an
                # overwritten resit reports
                if date = exam_dates[pset_name]
                    submit.grade.update_columns(updated_at: date.noon)
                end
            end

            # the grades association is cached from the writes above
            student.reload.assign_final_grade(admin)
        end

        puts registrations.join(" / ") + " per student:"
        failures = 0
        students.each do |mail, (name, expected, _grades)|
            grades = User.find_by(mail: mail).all_submits
            actual = registrations.map { |registration| grades[registration]&.assigned_grade }
            ok = actual == expected
            failures += 1 unless ok
            puts "  #{ok ? 'ok  ' : 'FAIL'} #{name.ljust(20)} #{actual.inspect.ljust(16)} (expected #{expected.inspect})"
        end

        puts
        puts failures.zero? ? "All #{students.size} students match." : "#{failures} of #{students.size} students do not match."

        # the one student whose resit moved from one attempt to another
        if notes = User.find_by(mail: "thirdtime@example.test").all_submits["sp1_resit"]&.notes
            puts
            puts "Notes on Tess Thirdtime's sp1_resit:"
            notes.lines.each { |line| puts "  #{line.chomp}" unless line.strip.empty? }
        end

        puts
        puts "Log in as #{admin.mail} and open the #{schedule.name} overview."
    end
end
