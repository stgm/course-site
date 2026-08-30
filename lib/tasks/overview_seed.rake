# Generated students, submits and grades for one schedule's grading overview,
# so the overview page can be looked at with realistic volume. Runs on its own
# and is safe to re-run: it deletes its previous output first, and every random
# choice is seeded with the schedule name, so a re-run reproduces the same data.
#
#   bin/rails dev:overview_seed                 # the default (self_register) schedule
#   bin/rails dev:overview_seed SCHEDULE=Herfst
#   bin/rails dev:overview_seed STUDENTS=40 GROUPS=2 SUBMIT_RATE=0.8 GRADED_RATE=0.9

module OverviewSeed

    MAIL_PREFIX = "overview-seed"

    module_function

    # A set of subgrade values whose formula result is a sensible grade: a pass
    # (-1), a fail (0), or a number in 1..10. Returns nil when the assignment has
    # no subgrades/formula, so the caller assigns a grade directly instead.
    def fitting_subgrades(config, rng)
        types = config["subgrades"]
        calc  = config["calculation"]
        return nil if types.blank? || calc.blank?

        sane = []
        20.times do
            candidate = types.each_with_object({}) do |(name, type), h|
                h[name] =
                    case type
                    when "boolean", "pass" then rng.rand < 0.85 ? -1 : 0
                    when "float"           then (rng.rand * 4 + 5).round(1)
                    else                        rng.rand(0..10) # integer
                    end
            end

            result = GradingFormulaEvaluator.evaluate(calc, candidate, aggregate_keys: types.keys)
            sane << [ candidate, result ] if result && (result.in?([ -1, 0 ]) || result.between?(1, 10))
        end
        return nil if sane.empty?

        passing = sane.select { |_candidate, result| result == -1 || result >= 5.5 }
        pool = (passing.any? && rng.rand < 0.9) ? passing : sane
        pool.sample(random: rng).first
    end

    # A directly assigned grade, for assignments without a formula.
    def direct_grade(type, rng)
        case type
        when "pass"
            rng.rand < 0.85 ? -1 : 0
        when "integer"
            rng.rand < 0.85 ? rng.rand(6..9) : rng.rand(3..5)
        else # float, points, nil
            rng.rand < 0.85 ? (rng.rand * 3.5 + 5.5).round(1) : (rng.rand * 1.5 + 4.0).round(1)
        end
    end

    FIRST_NAMES = %w[Emma Lucas Sophie Daan Julia Sem Tess Finn Noa Luuk Eva Bram
                     Lisa Milan Anna Thijs Fleur Jesse Roos Gijs Nina Ruben Sara
                     Teun Maud Cas Loes Stijn Fenna Joris Isa Niek Elin Bas Yara
                     Mees Lot Timo Britt Kai].freeze
    LAST_NAMES  = %w[Jansen Bakker Visser Smit Meijer Bos Vos Peters Hendriks Dekker
                     Brouwer Koster Groot Bosch Vermeer Dijkstra Kramer Post Kok
                     Timmermans Willems Maas Verhoeven Prins Kuiper Hoekstra Schouten
                     Blom Wolff Kool Nagel Boonstra Reijnders Sanders Evers Driessen
                     Aarts Coppens Timmer Heijmans].freeze

    def student_name(n)
        "#{FIRST_NAMES[(n - 1) % FIRST_NAMES.size]} #{LAST_NAMES[(n * 7) % LAST_NAMES.size]}"
    end

end

namespace :dev do
    desc "Fill a schedule's grading overview with generated students, submits and grades"
    task overview_seed: :environment do
        abort "dev:overview_seed only runs in development" unless Rails.env.development?

        student_count = Integer(ENV.fetch("STUDENTS", 40))
        group_count   = Integer(ENV.fetch("GROUPS", 2))
        submit_rate   = Float(ENV.fetch("SUBMIT_RATE", 0.8)) # share of visible assignments a student submits
        graded_rate   = Float(ENV.fetch("GRADED_RATE", 0.9)) # share of manual submits that get a published grade

        schedule =
            if ENV["SCHEDULE"].present?
                Schedule.find_by!(name: ENV["SCHEDULE"])
            else
                Schedule.default
            end

        if schedule.blank?
            abort "No default schedule (none has self_register set). " \
                  "Pass SCHEDULE=\"<name>\". Known: #{Schedule.pluck(:name).inspect}"
        end

        # Seeded with the schedule name: a re-run reproduces the same data.
        require "digest"
        seed = Digest::SHA256.hexdigest("overview-seed:#{schedule.name}").to_i(16) % (2**48)
        rng = Random.new(seed)
        puts "Schedule: #{schedule.name} (seed #{seed})"

        # The assignments the overview shows, taken from the same source the view
        # uses (schedule.grading_config.overview yields [name, flag, [[pset, weight]]]
        # rows). Final-grade psets are calculated, not submitted, so they drop out.
        visible_psets = schedule.grading_config.overview
            .flat_map { |_name, _flag, psets| psets.map { |pset, _weight| pset } }
            .compact
            .reject(&:final)
            .uniq
        abort "The overview for #{schedule.name} lists no assignments." if visible_psets.empty?
        puts "Visible assignments: #{visible_psets.size}"

        grader = User.where(mail: "#{OverviewSeed::MAIL_PREFIX}-grader@example.test").first_or_initialize
        grader.update!(name: "Olivia Grader", role: :head, schedule: schedule)
        Current.user = grader

        groups = (1..group_count).map do |n|
            group = Group.where(name: "Overview Seed #{(64 + n).chr}", schedule: schedule).first_or_create!
            group.graders << grader unless group.graders.include?(grader)
            group
        end

        # Delete the previous run's students (and, by dependent: :destroy, their
        # submits and grades) so the result does not depend on what was there.
        mail_pattern = "#{OverviewSeed::MAIL_PREFIX}-#{schedule.slug}-%@example.test"
        old = User.where("mail LIKE ?", mail_pattern)
        puts "Removing #{old.count} students from a previous run" if old.any?
        old.destroy_all

        created = 0
        published = 0
        pending = 0

        (1..student_count).each do |n|
            student = User.create!(
                mail: format("%s-%s-%02d@example.test", OverviewSeed::MAIL_PREFIX, schedule.slug, n),
                name: OverviewSeed.student_name(n),
                role: :student,
                schedule: schedule,
                status: :active
            )
            # second save on purpose: User::Groupable clears the group whenever
            # the schedule changes
            student.update!(group: groups[(n - 1) % groups.size])

            visible_psets.each do |pset|
                # Every branch draws from rng unconditionally and in a fixed
                # order, so the stream stays aligned across runs.
                submitted    = rng.rand < submit_rate
                submitted_at = rng.rand(1..60).days.ago
                grade_now    = rng.rand < graded_rate
                config       = schedule.grading_config.grades[pset.name]&.to_h || {}
                subgrades    = OverviewSeed.fitting_subgrades(config, rng)
                direct       = OverviewSeed.direct_grade(config["type"], rng)

                next unless submitted

                submit = student.submits.create!(pset: pset, submitted_at: submitted_at)
                created += 1

                # autograded assignments are always graded; manual ones 90% of the time
                unless pset.automatic || grade_now
                    pending += 1
                    next
                end

                grade = submit.create_grade
                if subgrades
                    grade.subgrades = subgrades
                    grade.grade = nil # let the formula produce the grade
                else
                    grade.grade = direct
                end
                grade.grader = grader
                grade.status = :published
                grade.save!

                submit.update_columns(auto_graded: true) if pset.automatic
                published += 1
            end
        end

        puts
        puts "Submits created:  #{created}"
        puts "Grades published: #{published}"
        puts "Awaiting grading: #{pending}"
        puts
        puts "Overview:      /overview/#{schedule.slug}"
        puts "Grader login:  #{grader.mail}"
    end
end
