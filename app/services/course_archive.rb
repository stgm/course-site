# Builds a single zip with everything needed to archive the course:
#
#   grades.xlsx                      all grades, same data as the xlsx export button
#   schedules/<slug>/grades.xlsx     the same, but only for this schedule
#   schedules/<slug>/grades-with-feedback.pdf
#                                    grades and feedback, one page per student
#   schedules/<slug>/syllabus.pdf    the schedule's syllabus page
#   schedules/<slug>/announcements.pdf
#   schedules/<slug>/final-grades.pdf
#
# Everything is generated synchronously; there is no job runner. Nothing is kept in
# memory as a whole: each document is rendered into its own temp file and copied into
# the archive, which is itself a temp file. Peak memory is one document's worth of
# Prawn/axlsx bookkeeping, not the size of the archive.
#
#   CourseArchive.new.write_to("/tmp/archive.zip")   # from the console
#
class CourseArchive

    # the scopes for the grade exports, shared with Admin::CourseController#export_grades;
    # without a schedule these cover the whole course
    #
    # everything the grade exports touch per student; without this the exports fire a
    # handful of queries per student and per submit
    #
    PRELOADS = [ :logins, :group, :schedule, { submits: [ :pset, { grade: :grader } ] } ].freeze

    def self.grade_export_scopes(schedule = nil)
        users = User.student.joins(:submits).distinct.includes(PRELOADS)
        psets = Pset.joins(:submits).distinct.order(:order)
        # all users who ever submitted something, students or not
        students = User.joins(:submits).distinct.order(:name).includes(PRELOADS)

        if schedule
            users = users.where(schedule: schedule)
            psets = psets.where(submits: { user_id: schedule.users })
            students = students.where(schedule: schedule)
        end

        [ users, psets, students ]
    end

    # the name the download is offered under, based on the course's short name
    #
    def self.filename
        course = Course.short_name.to_s.parameterize(preserve_case: true).presence || "course"
        "#{course}-archives-#{Date.current.iso8601}.zip"
    end

    # Returns the archive as a closed Tempfile. In a request, hand it to Rack so it is
    # cleaned up once the response has been sent (see Admin::CourseController#archive).
    #
    def to_tempfile
        with_locale do
            ZipWriter.to_tempfile(basename: "course-archive") { |zip| add_entries(zip) }
        end
    end

    # Writes the archive to a path of your choosing; convenient from the console.
    #
    def write_to(path)
        with_locale { Zip::OutputStream.open(path) { |zip| add_entries(zip) } }
        path
    end

    private

    # the request already sets the locale, but the archive is also generated from
    # the console every now and then
    #
    def with_locale(&block)
        I18n.with_locale(Course.language || I18n.default_locale, &block)
    end

    def add_entries(zip)
        # the course-wide xlsx covers every schedule; the per-student feedback is only
        # written per schedule, because rendering every student twice doubles the time
        # the whole archive takes
        add_entry(zip, "grades.xlsx") { |io| grades_xlsx(io) }

        Schedule.order(:name).each do |schedule|
            dir = "schedules/#{schedule.slug}"
            add_entry(zip, "#{dir}/grades.xlsx") { |io| grades_xlsx(io, schedule) }
            add_entry(zip, "#{dir}/grades-with-feedback.pdf") { |io| grades_overview_pdf(io, schedule) }
            if schedule.page.present?
                add_entry(zip, "#{dir}/syllabus.pdf") { |io| syllabus_pdf(io, schedule) }
            end
            add_entry(zip, "#{dir}/announcements.pdf") { |io| announcements_pdf(io, schedule) }
            add_entry(zip, "#{dir}/final-grades.pdf") { |io| final_grades_pdf(io, schedule) }
        end
    end

    def helpers
        @helpers ||= ApplicationController.helpers
    end

    def t(key, **options)
        I18n.t(key, **options)
    end

    def export_date
        I18n.l(Time.current, format: :long)
    end

    # write one entry, but never let a single broken page kill the whole download:
    # on failure the zip gets an error note in place of the file
    #
    # the document is generated into a scratch file first, so that a generator that
    # fails halfway has not already written a truncated entry into the archive
    #
    def add_entry(zip, filename)
        Tempfile.create([ "archive-entry", File.extname(filename) ], binmode: true) do |scratch|
            yield scratch
            scratch.rewind
            zip.put_next_entry(filename)
            IO.copy_stream(scratch, zip)
        end
    rescue => e
        Rails.logger.error("CourseArchive: could not generate #{filename}: #{e.class}: #{e.message}")
        zip.put_next_entry("#{filename}.ERROR.txt")
        zip.write("Could not generate #{filename}\n\n#{e.class}: #{e.message}\n\n#{e.backtrace&.first(20)&.join("\n")}\n")
    end

    #
    # grades
    #

    # caxlsx_rails always hands back a String, so this one entry is still built in
    # memory; it is by far the smallest of the documents here
    #
    def grades_xlsx(io, schedule = nil)
        users, psets, students = self.class.grade_export_scopes(schedule)
        io.write(ApplicationController.render(
            template: "admin/course/export_grades",
            formats: [ :xlsx ],
            assigns: { users: users, psets: psets, students: students, title: "Export grades" }
        ))
    end

    # the PDF equivalent of admin/course/export_grades.html.erb: a page per student
    # with all their submits and grades
    #
    def grades_overview_pdf(io, schedule = nil)
        _users, _psets, students = self.class.grade_export_scopes(schedule)

        pdf_document(io, landscape: true) do |pdf|
            pdf_heading(pdf, t("archive.grades.title"), schedule)

            pdf.text pdf_safe(t("archive.grades.no_students")), size: 10 if students.empty?

            groups = component_groups(schedule&.grading_config)

            students.each_with_index do |student, index|
                pdf.start_new_page if index > 0
                pdf.text pdf_safe("#{student.name} (#{student.defacto_student_identifier})"), size: 12, style: :bold
                pdf.move_down 4

                rows = grade_rows(student, groups)
                if rows.any?
                    draw_grade_rows(pdf, rows)
                else
                    pdf.text pdf_safe(t("archive.grades.no_submits")), size: 8
                end
            end
        end
    end

    # "correctness: 3 / style: 2" rather than "3 / 2": the numbers mean nothing on their own
    #
    def subgrade_summary(grade)
        grade.subgrades.to_h.map { |name, value| "#{name}: #{value.presence || '-'}" }.join(" / ")
    end

    # the components of the schedule, each with the assignments that make it up, plus a
    # closing group for the final grades. Nil when the course does not grade by component
    # at all, in which case every submit is simply listed
    #
    def component_groups(config)
        return nil if config.blank? || config.components.blank?

        groups = config.components.map do |name, component|
            [ name, component["submits"].to_h.keys + component["bonus"].to_h.keys ]
        end
        groups << [ t("archive.grades.final_grades"), config.calculation.keys ] if config.calculation.present?
        groups
    end

    # rows are tagged: [ :section, title ], [ :row, cells ] or [ :comment, text ]
    #
    def grade_rows(student, groups = nil)
        submits = student.submits.to_a
        return submits.flat_map { |submit| submit_rows(submit) } if groups.blank?

        rows = groups.flat_map do |title, assignments|
            matching = submits.select { |submit| assignments.include?(submit.pset&.name) }
                .sort_by { |submit| [ assignments.index(submit.pset.name), submit.created_at ] }
            next [] if matching.empty?

            [ [ :section, title ] ] + matching.flat_map { |submit| submit_rows(submit) }
        end

        # an archive should never silently drop everything a student handed in
        rows.presence || submits.flat_map { |submit| submit_rows(submit) }
    end

    def submit_rows(submit)
        grade = submit.grade
        unless grade.present?
            return [ [ :row, [
                pdf_safe(submit.pset&.name),
                submit.created_at.strftime("%d-%m-%Y %H:%M"),
                pdf_safe(t("archive.grades.not_graded")), "", "", ""
            ] ] ]
        end

        rows = [ [ :row, [
            pdf_safe(submit.pset&.name),
            submit.created_at.strftime("%d-%m-%Y %H:%M"),
            grade.updated_at.strftime("%d-%m-%Y %H:%M"),
            pdf_safe(helpers.translate_grade(grade.assigned_grade)),
            pdf_safe(grade.grader_name),
            pdf_safe(subgrade_summary(grade))
        ] ] ]
        # a comment spans the full width on a line of its own
        rows << [ :comment, pdf_safe(grade.comments) ] if grade.comments.present?
        rows
    end

    # how the six columns divide up the page
    GRADE_COLUMNS = [ 0.20, 0.12, 0.12, 0.06, 0.16, 0.34 ].freeze

    # laid out by hand rather than with prawn-table: for a few thousand rows the table
    # implementation spends most of its time measuring cells to fit column widths, and
    # these columns have known contents
    #
    ROW_HEIGHT = 9
    FONT_SIZE = 7
    CELL_PADDING = 2

    def grade_column_widths(pdf)
        GRADE_COLUMNS.map { |part| part * pdf.bounds.width }
    end

    def draw_grade_rows(pdf, rows)
        widths = grade_column_widths(pdf)
        header = %w[pset submitted graded grade grader subgrades].map { |key| pdf_safe(t("archive.grades.header.#{key}")) }

        pdf.line_width = 0.25
        draw_rule(pdf)
        draw_columns(pdf, header, widths, style: :bold)
        rows.each do |kind, content|
            case kind
            when :comment
                draw_comment(pdf, content)
            when :section
                draw_columns(pdf, [ content ], [ pdf.bounds.width ], style: :bold, header: header)
            else
                draw_columns(pdf, content, widths, header: header)
            end
        end
        pdf.move_down 4
    end

    # one submit on one line. draw_text puts the string down without any layout work,
    # which is an order of magnitude cheaper than text_box or prawn-table; the columns
    # hold names, dates and grades, so a line that does not fit is the exception
    #
    def draw_columns(pdf, cells, widths, style: :normal, header: nil)
        if pdf.cursor < ROW_HEIGHT + 4
            pdf.start_new_page
            # repeat the header when a student's rows run onto the next page; the header
            # always spans the grade columns, whatever this row does
            if header
                # close the top of the continued table
                draw_rule(pdf)
                draw_columns(pdf, header, grade_column_widths(pdf), style: :bold)
            end
        end

        top = pdf.cursor
        baseline = top - FONT_SIZE
        left = 0
        pdf.font("Helvetica", style: style) do
            cells.each_with_index do |text, column|
                pdf.draw_text fit_to_column(pdf, text.to_s, widths[column] - 2 * CELL_PADDING),
                    at: [ left + CELL_PADDING, baseline ], size: FONT_SIZE
                left += widths[column]
            end
        end
        pdf.move_down ROW_HEIGHT + 2

        # the grid, drawn by hand because there is no table to draw it
        draw_rule(pdf)
        left = 0
        ([ 0 ] + widths).each do |width|
            left += width
            pdf.stroke_vertical_line pdf.cursor + 2, top + 2, at: left
        end
    end

    # named draw_rule, not rule: the final grade section already has a rule() that
    # returns the wording of a grading rule
    #
    def draw_rule(pdf)
        pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor + 2
    end

    # a comment flows over as many lines as it needs and prawn breaks the page for it, so
    # the side edges are drawn afterwards, once it is known where the text ended up
    #
    def draw_comment(pdf, text)
        first_page = pdf.page_number
        top = pdf.cursor

        # inset like any other cell: the columns are drawn 2pt in from their edges
        pdf.move_down CELL_PADDING
        pdf.indent(CELL_PADDING, CELL_PADDING) do
            pdf.text text, size: FONT_SIZE, style: :italic
        end
        pdf.move_down CELL_PADDING
        bottom = pdf.cursor

        # note the last page before going anywhere: go_to_page moves page_number along
        last_page = pdf.page_number
        pdf.float do
            (first_page..last_page).each do |page|
                pdf.go_to_page(page)
                # a comment that runs onto the next page closes the top there itself; no
                # row broke the page, so nothing else draws that edge
                draw_rule(pdf) unless page == first_page
                draw_edges(pdf,
                    page == first_page ? top : pdf.bounds.top,
                    page == last_page ? bottom : 0)
            end
        end
        draw_rule(pdf)
    end

    def draw_edges(pdf, top, bottom)
        [ 0, pdf.bounds.width ].each { |x| pdf.stroke_vertical_line bottom + 2, top + 2, at: x }
    end

    def fit_to_column(pdf, text, width)
        return text if text.empty?
        full = pdf.width_of(text, size: FONT_SIZE)
        return text if full <= width

        # cut proportionally, the font is close enough to uniform for this
        keep = [ (text.length * width / full).to_i - 3, 1 ].max
        "#{text[0, keep]}..."
    end

    #
    # syllabus and announcements, per schedule
    #

    # the syllabus is the page linked to the schedule; Page.syllabus resolves the same
    # thing but only for the currently logged in user, so go through the schedule here
    #
    def syllabus_pdf(io, schedule)
        page = schedule.page

        pdf_document(io) do |pdf|
            pdf.text pdf_safe(export_line(schedule)), size: 9, align: :right
            pdf.move_down 12

            page.subpages.each_with_index do |subpage, index|
                pdf.start_new_page if index > 0
                append_markdown(pdf, subpage.content, asset_prefix: page.public_url, trusted: true)
            end
        end
    end

    def announcements_pdf(io, schedule)
        alerts = Alert.having_schedule_or_nil(schedule).where(published: true).reorder(created_at: :asc)

        pdf_document(io) do |pdf|
            pdf_heading(pdf, t(:announcements), schedule)

            if alerts.empty?
                pdf.text pdf_safe(t("archive.announcements.none")), size: 10
            end

            alerts.each do |alert|
                pdf.text pdf_safe(I18n.l(alert.created_at, format: :long)), size: 8
                pdf.text pdf_safe(alert.title), size: 13, style: :bold
                pdf.move_down 4
                append_markdown(pdf, alert.body)
                pdf.move_down 14
            end
        end
    end

    #
    # final grade calculation
    #

    # prawn-table only has one way to size columns: it measures the content, and then
    # divides any left over width in proportion to how wide each column could get. A
    # column holding a long comma separated list therefore swallows the page and leaves
    # the short columns at their bare content width, so say what the columns should be
    #
    #                     component  weight  share  condition
    COMPONENT_COLUMNS =  [ 0.28,     0.10,   0.10,  0.52 ].freeze
    #                            component  share  condition
    SINGLE_COMPONENT_COLUMNS = [ 0.30,      0.10,  0.60 ].freeze
    #                     assignment  type  parts  formula
    ASSIGNMENT_COLUMNS = [ 0.26,      0.12, 0.31,  0.31 ].freeze
    #                     assignment  weight
    SUBMITS_COLUMNS =    [ 0.72,      0.28 ].freeze

    def draw_table(pdf, rows, columns, width: pdf.bounds.width, padding: 3)
        pdf.table(rows,
            header: true,
            width: width,
            column_widths: columns.map { |part| part * width },
            cell_style: { size: 8, padding: padding }) do
            row(0).font_style = :bold
        end
    end

    # explains, in prose and tables, how every final grade of this schedule is
    # calculated, so that an exam committee can follow it without reading grading.yml
    #
    def final_grades_pdf(io, schedule)
        config = schedule.grading_config

        pdf_document(io) do |pdf|
            pdf_heading(pdf, t("archive.final_grades.title"), schedule)

            if config.calculation.blank?
                pdf.text pdf_safe(t("archive.final_grades.none")), size: 10
                next
            end

            pdf.text pdf_safe(t("archive.final_grades.intro")), size: 10
            pdf.move_down 14

            # every component is only transcribed once; later final grades refer back to
            # the first one, because a resit usually repeats most of it
            described = []
            reference = nil

            config.calculation.each do |final_name, components|
                describe_final_grade(pdf, config, final_name, components, reference, described)
                reference ||= [ final_name, components ]
            end

            describe_rounding(pdf)
            describe_assignment_grades(pdf, config)
        end
    end

    def describe_final_grade(pdf, config, final_name, components, reference, described)
        pdf.text pdf_safe(t("archive.final_grades.heading", name: final_name)), size: 14, style: :bold
        pdf.move_down 4

        if reference && reference.last == components
            pdf.text pdf_safe(t("archive.final_grades.same_as", name: reference.first)), size: 10
            pdf.move_down 14
            return
        end

        # a single component has nothing to weigh against anything
        single = components.size == 1
        pdf.text pdf_safe(t("archive.final_grades.#{single ? 'single_component' : 'weighted_average'}")), size: 10
        pdf.move_down 6

        headers = single ? %w[component share condition] : %w[component weight share condition]
        rows = [ headers.map { |key| pdf_safe(t("archive.final_grades.header.#{key}")) } ]
        total_weight = components.values.sum
        components.each do |component_name, weight|
            component = config.components[component_name]
            row = [ pdf_safe(component_name) ]
            row << weight.to_s unless single
            row += [ weight_share(weight, total_weight), pdf_safe(component_condition(component, config)) ]
            rows << row
        end
        draw_table(pdf, rows, single ? SINGLE_COMPONENT_COLUMNS : COMPONENT_COLUMNS, padding: 4)
        pdf.move_down 10

        # only worth comparing when the two grades actually have components in common;
        # a resit built from entirely different parts is not a variation on the first
        differences = shares_components?(reference, components) ? component_differences(reference.last, components) : []
        if differences.any?
            pdf.text pdf_safe(t("archive.final_grades.compared_to",
                name: reference.first, differences: differences.join("; "))), size: 10
            pdf.move_down 4
        end

        repeated = components.keys.select { |name| described.include?(name) }
        if repeated.any?
            pdf.text pdf_safe(repeated_summary(repeated)), size: 9, style: :italic
            pdf.move_down 8
        end

        components.each_key do |component_name|
            next if described.include?(component_name)
            describe_component(pdf, config, component_name)
            described << component_name
        end
        pdf.move_down 6
    end

    def repeated_summary(names)
        t("archive.final_grades.not_repeated", count: names.size, names: names.join(", "))
    end

    # weights are proportional, so the share of the total says more than the weight itself
    #
    def weight_share(weight, total_weight)
        return "" if total_weight.to_f.zero?
        percentage = weight * 100.0 / total_weight
        format(percentage.round(1) == percentage.round ? "%d%%" : "%.1f%%", percentage)
    end

    # the conditions a component must meet before it counts, summarised for the overview table
    #
    def component_condition(component, config)
        return "" if component.blank?

        conditions = []
        if component["attempt_required"]
            # with a single assignment "all assignments attempted" reads as a mistake
            conditions << t("archive.final_grades.condition.attempt_required", count: component["submits"].size)
        end
        if single_pass_required?(component, config)
            # "at least 5.5" for a pass/fail assignment only means it has to be passed
            conditions << t("archive.final_grades.condition.passed")
        elsif component["minimum"]
            conditions << t("archive.final_grades.condition.minimum", minimum: component["minimum"])
        end
        conditions << t("archive.final_grades.condition.required") if component["required"]
        if component["type"] == "points" && component["submits"].value?(0)
            conditions << t("archive.final_grades.condition.zero_weight_required")
        end
        return t("archive.final_grades.condition.none") if conditions.empty?

        conditions.join("; ")
    end

    def shares_components?(reference, components)
        reference.present? && (reference.last.keys & components.keys).any?
    end

    # what sets this final grade apart from the one described earlier
    #
    def component_differences(reference, components)
        differences = []

        (components.keys - reference.keys).each do |name|
            differences << t("archive.final_grades.difference.used_instead", name: name, weight: components[name])
        end
        (reference.keys - components.keys).each do |name|
            differences << t("archive.final_grades.difference.not_used", name: name)
        end
        (components.keys & reference.keys).each do |name|
            next if components[name] == reference[name]
            differences << t("archive.final_grades.difference.other_weight",
                name: name, weight: components[name], previous: reference[name])
        end

        differences
    end

    # the strategies of User::FinalGradeCalculator, in words. A component built from a
    # single assignment goes through the same code, but "the average of the grades" or
    # "points earned out of points available" only confuses a reader when there is one
    # grade, so those are worded separately
    #
    def component_strategy(component, config)
        strategy = component["type"]
        strategy = "average" unless strategy.in?([ "points", "maximum" ])
        # the points available are worth naming: they are what the grade is measured against
        return t("archive.final_grades.strategy.points", count: points_available(component)) if strategy == "points"

        t("archive.final_grades.strategy.#{strategy}")
    end

    # what User::FinalGradeCalculator#get_points_potential arrives at: the weights of the
    # assignments, but never more than an explicit maximum
    #
    def points_available(component)
        total = component["submits"].to_h.values.sum
        [ component["maximum"], total ].compact.min
    end

    # how the one assignment of a component turns into the component grade. Only a points
    # component converts anything: elsewhere the grade carries over unchanged
    #
    def single_submit_note(component, config)
        return nil unless component["type"] == "points"

        name = component["submits"].to_h.keys.first
        # a pass counts for the full weight, so a points component of one pass/fail
        # assignment can only ever come out as a 10 or a 1
        if config.grades[name].to_h["type"] == "pass"
            return rule(single_pass_required?(component, config) ? :single_pass_required : :single_pass, name: name)
        end

        rule(:single_points, name: name, count: points_available(component))
    end

    # a single pass/fail assignment scoring points fails the minimum whenever it is not
    # passed, so the component is either a 10 or a NAV and the minimum needs no bullet
    # of its own
    #
    def single_pass_required?(component, config)
        submits = component["submits"].to_h
        return false unless component["type"] == "points" && submits.size == 1
        return false unless component["minimum"].to_f > 1

        config.grades[submits.keys.first].to_h["type"] == "pass"
    end

    def describe_component(pdf, config, component_name)
        component = config.components[component_name]
        if component.blank?
            pdf.text pdf_safe(t("archive.final_grades.component_undefined", name: component_name)),
                size: 9, style: :italic
            return
        end

        pdf.text pdf_safe(t("archive.final_grades.component_heading", name: component_name)), size: 11, style: :bold
        pdf.move_down 3

        # a component of one assignment simply is that assignment; describing it as an
        # average or as points out of points only obscures that
        single = component["submits"].to_h.size == 1
        if single
            pdf.text pdf_safe(t("archive.final_grades.component_is_single",
                name: component["submits"].to_h.keys.first)), size: 9
        else
            pdf.text pdf_safe(t("archive.final_grades.component_is",
                strategy: component_strategy(component, config))), size: 9
        end

        # the note about a required pass already says what happens below the minimum
        rules = component_rules(component, skip_minimum: single_pass_required?(component, config))
        rules.unshift(single_submit_note(component, config)) if single
        rules = rules.compact
        if rules.any?
            pdf.move_down 3
            rules.each { |rule| pdf.text pdf_safe("- #{rule}"), size: 9 }
        end
        pdf.move_down 5

        # the table would hold a single row saying what the sentence already said
        if single
            pdf.move_down 5
            return
        end

        label = component["type"] == "points" ? "points_available" : "weight"
        rows = [ [
            pdf_safe(t("archive.final_grades.header.assignment")),
            pdf_safe(t("archive.final_grades.header.#{label}"))
        ] ]
        component["submits"].each { |name, weight| rows << [ pdf_safe(name), weight.to_s ] }
        component["bonus"]&.each do |name, weight|
            rows << [ pdf_safe(t("archive.final_grades.bonus_label", name: name)), weight.to_s ]
        end

        draw_table(pdf, rows, SUBMITS_COLUMNS, width: pdf.bounds.width / 2)
        pdf.move_down 10
    end

    # the exceptions and extra conditions that User::FinalGradeCalculator applies
    #
    def component_rules(component, skip_minimum: false)
        rules = []
        rules << rule(:minimum, minimum: component["minimum"]) if component["minimum"] && !skip_minimum
        rules << rule(:maximum, maximum: component["maximum"]) if component["maximum"]
        rules << rule(:attempt_required, count: component["submits"].size) if component["attempt_required"]
        # when every assignment must have been attempted, what happens to a missing
        # grade has already been said
        rules << missing_rule(component) unless component["attempt_required"]
        rules << rule(:required) if component["required"]
        rules << rule(:drop_lowest) if component["drop"].to_s == "lowest"
        rules << rule(:bonus) if component["bonus"].present?
        rules << rule(:zero_weight_required) if component["type"] == "points" && component["submits"].value?(0)
        rules << rule(:deadline, deadline: component["deadline"]) if component["deadline"].present?
        rules.compact
    end

    # how a missing (not handed in, not graded) assignment affects the component;
    # `fill_missing` only has meaning for the average strategy, because points are
    # always counted as 0 when missing, and the maximum strategy always cancels
    #
    def missing_rule(component)
        return rule(:missing_scores_zero) if component["type"] == "points"
        return rule(:missing_cancels) if component["type"] == "maximum"

        fill = component["fill_missing"]
        return rule(:missing_cancels) if fill.blank?
        return rule(:missing_counts_as, value: fill) if fill.is_a?(Numeric)

        rule(:missing_allowed)
    end

    def rule(name, **options)
        t("archive.final_grades.rule.#{name}", **options)
    end

    def describe_rounding(pdf)
        pdf.text pdf_safe(t("archive.final_grades.rounding.title")), size: 14, style: :bold
        pdf.move_down 4
        pdf.text pdf_safe(t("archive.final_grades.rounding.intro")), size: 10
        pdf.move_down 3
        t("archive.final_grades.rounding.rules").each { |line| pdf.text pdf_safe("- #{line}"), size: 9 }
        pdf.move_down 4
        pdf.text pdf_safe(t("archive.final_grades.rounding.note")), size: 9
        pdf.move_down 14
    end

    # how the grade of a single assignment comes about, from its subgrades
    #
    def describe_assignment_grades(pdf, config)
        assignments = config.calculation.values.flat_map do |components|
            components.keys.flat_map { |name| config.components[name]&.dig("submits")&.keys || [] }
        end.uniq

        return if assignments.empty?

        pdf.start_new_page unless pdf.cursor == pdf.bounds.top
        pdf.text pdf_safe(t("archive.final_grades.assignments.title")), size: 14, style: :bold
        pdf.move_down 4
        pdf.text pdf_safe(t("archive.final_grades.assignments.intro")), size: 10
        pdf.move_down 6

        rows = [ %w[assignment type parts formula].map { |key| pdf_safe(t("archive.final_grades.header.#{key}")) } ]
        assignments.each do |name|
            grade_config = config.grades[name] || {}
            automatic = grade_config["automatic"].to_h.keys
            parts = grade_config["subgrades"].to_h.keys.map do |part|
                automatic.include?(part) ? t("archive.final_grades.assignments.automatic", name: part) : part
            end
            rows << [
                pdf_safe(name),
                pdf_safe(grade_config["type"] || "float"),
                pdf_safe(parts.join(", ")),
                pdf_safe(grade_config["calculation"])
            ]
        end

        draw_table(pdf, rows, ASSIGNMENT_COLUMNS)
        pdf.move_down 8
        pdf.text pdf_safe(t("archive.final_grades.assignments.note")), size: 9
    end

    #
    # pdf plumbing
    #

    # prawn's built-in fonts only cover Windows-1252, and there is no font shipped with
    # the app; transliterate anything else (accents survive, exotic characters become ?)
    #
    def pdf_safe(text)
        text.to_s.encode(
            "Windows-1252",
            fallback: ->(char) { I18n.transliterate(char, replacement: "?") }
        ).encode("UTF-8")
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end

    # renders straight into the given IO, so the finished PDF is never also held as a
    # String; prawn still keeps the document itself in memory until it is rendered
    #
    def pdf_document(io, landscape: false)
        # text is transliterated by pdf_safe, so the warning about the built-in fonts
        # not supporting UTF-8 is only noise
        Prawn::Fonts::AFM.hide_m17n_warning = true

        pdf = Prawn::Document.new(
            page_size: "A4",
            page_layout: landscape ? :landscape : :portrait,
            margin: 36
        )
        yield pdf
        pdf.render(io)
    end

    def pdf_heading(pdf, what, schedule)
        pdf.text pdf_safe(document_title(what, schedule)), size: 16, style: :bold
        pdf.text pdf_safe(export_line(schedule)), size: 9
        pdf.move_down 12
    end

    # "23 maart 2026 - 29 mei 2026, geexporteerd op 28 juli 2026 13:49"; the period comes
    # from _settings in the schedule's grading.yml and is simply left out when not set
    #
    def export_line(schedule = nil)
        parts = [ schedule && schedule_period(schedule), t("archive.exported_on", date: export_date) ]
        parts.compact.join(", ").upcase_first
    end

    def schedule_period(schedule)
        settings = schedule.grading_config.settings.to_h
        starts = config_date(settings["start_date"])
        ends = config_date(settings["end_date"])
        return nil unless starts && ends

        "#{I18n.l(starts, format: :long)} - #{I18n.l(ends, format: :long)}"
    end

    # dates in grading.yml are written as 23/3/26, but yaml turns an iso date into a Date
    #
    def config_date(value)
        return value if value.respond_to?(:strftime)
        Date.strptime(value.to_s, "%d/%m/%y")
    rescue Date::Error, TypeError
        nil
    end

    # "Cijfers Programmeren 2 - Lente", or without the schedule when the course only
    # runs one: naming it then says nothing
    #
    def document_title(what, schedule)
        title = "#{what} #{Course.long_name}"
        title += " - #{schedule.name}" if schedule && several_schedules?
        title
    end

    def several_schedules?
        return @several_schedules unless @several_schedules.nil?
        @several_schedules = Schedule.count > 1
    end

    # render markdown through the same helper the site uses, then feed the HTML to
    # prawn-html; that has no notion of tables, so tables are pulled out of the flow
    # and drawn with prawn-table instead
    #
    def append_markdown(pdf, markdown, **options)
        html = helpers.render_markdown(markdown.to_s, **options)
        doc = simplify_html(html)

        buffer = []
        append_nodes(pdf, doc.children, buffer)
        flush_html(pdf, buffer)
    rescue => e
        Rails.logger.warn("CourseArchive: falling back to plain text (#{e.class}: #{e.message})")
        pdf.text pdf_safe(markdown), size: 9
    end

    # collect nodes into a buffer of html for prawn-html, interrupting the buffer
    # whenever a table shows up; tables are often wrapped in a div, so descend into
    # any element that contains one
    #
    def append_nodes(pdf, nodes, buffer)
        nodes.each do |node|
            if node.name == "table"
                flush_html(pdf, buffer)
                append_table(pdf, node)
            elsif node.element? && node.css("table").any?
                flush_html(pdf, buffer)
                append_nodes(pdf, node.children, buffer)
            else
                buffer << node
            end
        end
    end

    def flush_html(pdf, buffer)
        html = buffer.map(&:to_html).join
        buffer.clear
        PrawnHtml.append_html(pdf, pdf_safe(html)) if html.strip.present?
    end

    def append_table(pdf, node)
        rows = node.css("tr").map { |tr| tr.css("th, td").map { |cell| pdf_safe(cell.text.squish) } }
        rows.reject!(&:empty?)
        return if rows.empty?

        # prawn-table needs every row to have the same number of columns
        columns = rows.map(&:size).max
        rows.each { |row| row.fill("", row.size...columns) }

        pdf.table(rows, header: node.css("th").any?, width: pdf.bounds.width, cell_style: { size: 8, padding: 3 })
        pdf.move_down 10
    rescue Prawn::Errors::CannotFit, Prawn::Errors::CannotGroup
        pdf.text pdf_safe(rows.map { |row| row.join(" | ") }.join("\n")), size: 8
        pdf.move_down 10
    end

    # prawn-html cannot load remote images and chokes on the markup that katex and
    # coderay produce, so simplify all of that away first
    #
    def simplify_html(html)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)

        doc.css("script, style").each(&:remove)

        # kramdown wraps the items of a "loose" list (items separated by blank lines) in
        # paragraphs; prawn-html then puts the bullet and the text on separate lines, so
        # unwrap the paragraph that opens a list item
        doc.css("li > p:first-child").each { |paragraph| paragraph.replace(paragraph.inner_html) }

        doc.css("img").each do |img|
            label = img["alt"].presence || img["src"].presence || "image"
            img.replace("<p>[#{CGI.escapeHTML(label)}]</p>")
        end

        # nested tables cannot be lifted out of the text flow, flatten those to lines
        doc.css("table table").each do |table|
            lines = table.css("tr").map do |tr|
                CGI.escapeHTML(tr.css("th, td").map { |cell| cell.text.squish }.join(" | "))
            end
            table.replace("<p>#{lines.join("<br>")}</p>")
        end

        doc
    end

end
