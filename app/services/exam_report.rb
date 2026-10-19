# Renders the report of an exam that has been held: where everyone sat, with
# full names and when they first and last submitted.
#
# Page 1 draws the room, cut down to the rows and columns that were used. It
# is drawn in whichever page orientation gives the tables the most room. The
# map already carries every name and time, so the report is that one page.
# Only when a name would have to be printed smaller than MIN_FONT_SIZE do the
# pages after it list everyone by name. The PDF is vector, so a crowded room
# can still be read by printing the one page on A3.
class ExamReport
    include PdfText

    MARGIN = 28
    HEADER_HEIGHT = 74
    FOOTER_HEIGHT = 26
    GUTTER = 14            # room for the row numbers and column letters
    MAX_CELL_HEIGHT_RATIO = 0.75
    MIN_FONT_SIZE = 5      # smallest size a name may shrink to on the map

    INK = "222222"
    MUTED = "777777"
    LINE = "BBBBBB"
    DISABLED_FILL = "EEEEEE"
    SEAT_FILL = "F2F7FC"
    SEAT_LINE = "5B7DA8"

    def initialize(exam)
        @exam = exam
        @submits = exam.pset.submits.includes(:user).where.not(seat: nil).to_a
        @submits.reject! { |submit| Exam.seat_coordinates(submit.seat).first.nil? }
        @by_seat = @submits.index_by(&:seat)
        @names_too_small = false
    end

    # Returns the finished PDF as a string.
    def render
        Prawn::Fonts::AFM.hide_m17n_warning = true

        pdf = Prawn::Document.new(page_size: "A4", page_layout: orientation, margin: MARGIN,
                            info: { Title: pdf_safe(title) })
        draw_header(pdf)
        draw_room(pdf)
        if @names_too_small
            draw_list(pdf)
            draw_page_numbers(pdf)
        end
        pdf.render
    end

    # Returns :landscape or :portrait, whichever gives the tables more room.
    def orientation
        @orientation ||= layout_for(:landscape)[:area] > layout_for(:portrait)[:area] ? :landscape : :portrait
    end

    # Returns the rows and columns that have someone at them, as ranges.
    def bounds
        @bounds ||= begin
            coordinates = @submits.map { |submit| Exam.seat_coordinates(submit.seat) }
            rows = coordinates.map(&:first)
            cols = coordinates.map(&:last)
            { rows: (rows.min..rows.max), cols: (cols.min..cols.max) }
        end
    end

    private

    def page_size_for(layout)
        width, height = PDF::Core::PageGeometry::SIZES["A4"]
        layout == :landscape ? [ height, width ] : [ width, height ]
    end

    # Works out how big a table can be drawn on a page in the given orientation.
    def layout_for(layout)
        width, height = page_size_for(layout)
        rows = bounds[:rows].size
        cols = bounds[:cols].size
        stagger = @exam.room_stagger? ? 0.5 : 0

        avail_w = width - 2 * MARGIN - GUTTER
        avail_h = height - 2 * MARGIN - HEADER_HEIGHT - FOOTER_HEIGHT - GUTTER - 22

        cell_w = avail_w / (cols + stagger)
        cell_h = [ avail_h / rows, cell_w * MAX_CELL_HEIGHT_RATIO ].min
        cell_w = [ cell_w, cell_h / MAX_CELL_HEIGHT_RATIO ].min if cell_h < cell_w * MAX_CELL_HEIGHT_RATIO

        { cell_w: cell_w, cell_h: cell_h, area: cell_w * cell_h }
    end

    #-- page 1 -------------------------------------------------------------

    def draw_header(pdf)
        pdf.fill_color INK
        pdf.text pdf_safe(title), size: 18, style: :bold
        pdf.move_down 6

        pdf.text pdf_safe(summary_line), size: 9
        pdf.move_down 10
    end

    # The course name, a colon and the humanized exam name.
    def title
        "#{Course.long_name}: #{@exam.name.humanize}"
    end

    def summary_line
        parts = [ "#{@submits.size} #{'student'.pluralize(@submits.size)}" ]
        parts << first_seen.in_time_zone.strftime("%-d %B %Y") if first_seen
        parts << "times are first and last submit"
        parts.join("  |  ")
    end

    def draw_room(pdf)
        size = layout_for(orientation)
        cell_w = size[:cell_w]
        cell_h = size[:cell_h]
        rows = bounds[:rows]
        cols = bounds[:cols]
        stagger = @exam.room_stagger?

        left = pdf.bounds.left + GUTTER
        top = pdf.cursor

        # the back row is drawn first, at the top; row 1 is the front
        rows.to_a.reverse.each_with_index do |row, line|
            y = top - line * cell_h
            offset = stagger && row.even? ? cell_w / 2 : 0

            pdf.fill_color MUTED
            pdf.text_box row.to_s, at: [ pdf.bounds.left, y - cell_h / 2 + 4 ], width: GUTTER - 3,
                height: 9, align: :right, size: 7

            cols.each_with_index do |col, index|
                draw_table(pdf, @exam.class.seat_for(row, col), left + offset + index * cell_w, y, cell_w, cell_h)
            end
        end

        # column letters below the front row, above the front bar
        bottom = top - rows.size * cell_h
        pdf.fill_color MUTED
        cols.each_with_index do |col, index|
            pdf.text_box pdf_safe(@exam.column_label(col)), at: [ left + index * cell_w, bottom - 3 ],
                width: cell_w, height: 9, align: :center, size: 7
        end

        draw_front_bar(pdf, left, bottom - GUTTER - 2, cell_w * (cols.size + (stagger ? 0.5 : 0)))
    end

    def draw_table(pdf, seat, x, y, width, height)
        gap = 2
        x += gap / 2.0
        y -= gap / 2.0
        width -= gap
        height -= gap
        submit = @by_seat[seat]

        pdf.line_width 0.5
        if submit
            pdf.fill_color SEAT_FILL
            pdf.stroke_color SEAT_LINE
            pdf.fill_and_stroke_rounded_rectangle [ x, y ], width, height, 3
        elsif @exam.seat_disabled?(seat)
            pdf.fill_color DISABLED_FILL
            pdf.fill_rectangle [ x, y ], width, height
            return
        else
            pdf.stroke_color LINE
            pdf.dash 2, space: 2
            pdf.stroke_rounded_rectangle [ x, y ], width, height, 3
            pdf.undash
            return
        end

        pad = 3
        pdf.fill_color MUTED
        shrunk_text(pdf, pdf_safe(@exam.seat_label(seat)), at: [ x + pad, y - pad ],
            width: width - 2 * pad, height: 8, size: 6)

        pdf.fill_color INK
        @names_too_small = true unless shrunk_text(pdf, pdf_safe(submit.user_name),
            at: [ x + pad, y - 11 ], width: width - 2 * pad, height: height - 22, size: 9,
            align: :center, valign: :center)

        pdf.fill_color MUTED
        shrunk_text(pdf, "#{format_time(submit.created_at)} - #{format_time(submit.submitted_at)}",
            at: [ x + pad, y - height + 10 ], width: width - 2 * pad, height: 8, size: 6,
            align: :right)
    end

    # Prints text in a box, shrinking it down to MIN_FONT_SIZE at most. Returns
    # whether all of it fitted; a box too small for even one line counts as not.
    def shrunk_text(pdf, text, **options)
        return false if options[:height] < MIN_FONT_SIZE

        pdf.text_box(text, min_font_size: MIN_FONT_SIZE, overflow: :shrink_to_fit, **options).blank?
    rescue Prawn::Errors::CannotFit
        false
    end

    def draw_front_bar(pdf, left, y, width)
        pdf.fill_color "DDDDDD"
        pdf.fill_rectangle [ left, y ], width, 12
        pdf.fill_color MUTED
        pdf.text_box "FRONT OF THE ROOM", at: [ left, y - 2 ], width: width, height: 10,
            size: 7, align: :center, character_spacing: 2
    end

    #-- following pages ----------------------------------------------------

    def draw_list(pdf)
        pdf.start_new_page
        pdf.fill_color INK
        pdf.text "Everyone by name", size: 14, style: :bold
        pdf.move_down 8

        rows = [ [ "Name", "Table", "First submit", "Last submit" ] ]
        @submits.sort_by { |submit| submit.user_name.to_s.downcase }.each do |submit|
            rows << [
                pdf_safe(submit.user_name),
                pdf_safe(@exam.seat_label(submit.seat)),
                format_time(submit.created_at, with_date: multiple_days?),
                format_time(submit.submitted_at, with_date: multiple_days?)
            ]
        end

        pdf.table(rows, header: true, width: pdf.bounds.width, row_colors: [ "FFFFFF", "F6F6F6" ],
                cell_style: { size: 9, padding: [ 4, 6 ], border_color: "DDDDDD", border_width: 0.5 }) do
            row(0).font_style = :bold
            row(0).background_color = "E4E8EE"
            columns(1..3).align = :left
        end
    end

    def draw_page_numbers(pdf)
        pdf.number_pages "<page> / <total>", at: [ pdf.bounds.right - 60, -8 ], width: 60, align: :right,
            size: 7, color: MUTED
    end

    #-- times --------------------------------------------------------------

    # The first time anyone opened the exam. The submit row is created when a
    # student first opens the exam, and no earlier history is kept.
    def first_seen
        @first_seen ||= @submits.map(&:created_at).compact.min
    end

    def last_seen
        @last_seen ||= @submits.map(&:submitted_at).compact.max
    end

    def multiple_days?
        return false if first_seen.nil? || last_seen.nil?
        first_seen.in_time_zone.to_date != last_seen.in_time_zone.to_date
    end

    def format_time(time, with_date: false)
        return "-" if time.nil?
        time.in_time_zone.strftime(with_date ? "%-d-%-m %H:%M" : "%H:%M")
    end

end
