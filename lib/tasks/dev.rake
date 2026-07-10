namespace :dev do
    desc "Seed the development database with a schedule, a grader, students and a test pset"
    task seed: :environment do
        # Loading a course repo overwrites Settings.grading wholesale, which drops
        # the grading entry created below. Re-run this task after importing a course.
        abort "dev:seed only runs in development" unless Rails.env.development?

        test_pset = "arrow-nav-test"

        students = {
            "alice@example.test" => "Alice Anderson",
            "bob@example.test" => "Bob Bakker",
            "carla@example.test" => "Carla Cruz",
            "dirk@example.test" => "Dirk Dekker"
        }

        grading_entry = {
            "is_test" => true,
            "type" => "points",
            "subgrades" => {
                "part_a" => "integer",
                "part_b" => "integer",
                "part_c" => "float",
                "bonus" => "integer"
            },
            "calculation" => "part_a + part_b + part_c + bonus"
        }

        # self_register makes this the default schedule
        schedule = Schedule.where(name: "Development").first_or_create!(self_register: true)
        puts "Schedule: #{schedule.name}"

        group = Group.where(name: "Development Group", schedule: schedule).first_or_create!
        puts "Group: #{group.name}"

        # a grader sees exactly the students of the groups assigned to them
        grader = User.where(mail: "grader@example.test").first_or_initialize
        grader.update!(name: "Gerda Grader", role: :head, schedule: schedule)
        group.graders << grader unless group.graders.include?(grader)
        puts "Grader: #{grader.name} <#{grader.mail}>"

        students.each do |mail, name|
            student = User.where(mail: mail).first_or_initialize
            student.update!(name: name, role: :student, schedule: schedule, group: group)
            puts "Student: #{student.name}"
        end

        pset = Pset.where(name: test_pset).first_or_create!(order: 999)

        # grading config lives in the settings table, keyed on the pset name
        grading = Settings.grading || {}
        grading["grades"] = (grading["grades"] || {}).merge(test_pset => grading_entry)
        GradingConfig.load grading
        puts "Test pset: #{pset.name} (#{grading_entry['subgrades'].keys.join(', ')})"

        # without this the Tests menu item stays hidden for a head
        Settings.tests_present = true

        puts
        puts "Log in as #{grader.mail} and open /tests/#{pset.id}/results"
    end
end
