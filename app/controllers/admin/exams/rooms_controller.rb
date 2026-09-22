# Mapping the exam room: which student is sitting at which table, and what the
# room looks like in the first place. Split off from Admin::ExamsController,
# which is about running the exam session itself.
#
# Every change redirects back to #show, which re-renders the room inside its
# turbo frame. That way two people mapping the room at the same time see each
# other's work, and there is one place where the room is drawn.
#
class Admin::Exams::RoomsController < AdminController

    before_action :find_exam

    layout "navbar"

    # The page layout is picked by the body class, which otherwise comes from
    # the controller name: this is the exam session page under another name,
    # and wants the same full-width grid rather than the one with a sidebar.
    before_action { @body_class = "exams" }

    def show
        @students = @exam.active_submits
        session[:exam_view] = "room"

        # a phase in the URL is a deliberate step back or forward and does not
        # change how far the exam has actually got
        @phase = params[:phase].presence || @exam.room_phase
        @phase = @exam.room_phase unless @phase.in?(Exam::ROOM_PHASES)
    end

    # Seat one student at one table, move them there from another table, or
    # empty the table again. Every placement goes through here, so this is
    # where a placement that would lose information is refused.
    def place
        seat = params[:seat].to_s

        if !@exam.seat_within_room?(seat)
            flash[:alert] = "That table is not part of the room."
        elsif @exam.seat_disabled?(seat)
            flash[:alert] = "Table #{@exam.seat_label(seat)} is switched off."
        elsif params[:submit_id].blank?
            clear_seat seat
        else
            fill_seat seat
        end

        redirect_back_to_room
    end

    # Dimensions, the half-table indent, which tables are really there and what
    # the columns are called.
    def layout
        permitted = params.expect(room: [ :rows, :cols, :stagger, :toggle_seat, :add, :remove, labels: {} ])

        return add_to_room(permitted[:add]) if permitted[:add].present?
        return remove_from_room(permitted[:remove]) if permitted[:remove].present?

        attrs = {}
        attrs["rows"] = permitted[:rows].to_i.clamp(1, 40) if permitted[:rows].present?
        attrs["cols"] = permitted[:cols].to_i.clamp(1, 40) if permitted[:cols].present?
        if permitted.key?(:stagger)
            attrs["stagger"] = permitted[:stagger].present? && permitted[:stagger] != "0"
        end
        attrs["labels"] = permitted[:labels].to_h.reject { |_col, label| label.blank? } if permitted.key?(:labels)

        if permitted[:toggle_seat].present?
            toggled = toggle_disabled_seat(permitted[:toggle_seat])
            return redirect_back_to_room if toggled.nil?
            attrs["disabled"] = toggled
        end

        # Once anybody is at a table the room stops shrinking. Which tables a
        # smaller room would drop is not obvious while you are typing in it,
        # and losing a placement is exactly the mistake the map exists to
        # prevent, so the whole direction is closed off rather than confirmed.
        if shrinking?(attrs)
            placed = @exam.placed_submits.count
            if placed.positive?
                flash[:alert] = "The room cannot be made smaller while " \
                                "#{placed} #{'student'.pluralize(placed)} " \
                                "#{placed == 1 ? 'is' : 'are'} at a table. " \
                                "Take them off their tables first."
                return redirect_back_to_room
            end
        end

        @exam.room = attrs
        @exam.save!

        redirect_back_to_room
    end

    # Step between defining the room, placing students and watching the exam.
    def phase
        wanted = params[:phase].to_s

        unless wanted.in?(Exam::ROOM_PHASES)
            flash[:alert] = "Unknown phase."
            return redirect_back_to_room
        end

        if wanted != "define" && @exam.enabled_seats.empty?
            flash[:alert] = "Define the room first: it has no tables."
            return redirect_to admin_exam_room_path(@exam, phase: "define")
        end

        # stepping back to correct something does not undo the progress made
        if Exam::ROOM_PHASES.index(wanted) > Exam::ROOM_PHASES.index(@exam.room_phase)
            @exam.room_phase = wanted
            @exam.save!
        end

        redirect_to admin_exam_room_path(@exam, phase: wanted)
    end

    private

    def find_exam
        @exam = Exam.find(params[:exam_id])
    end

    def redirect_back_to_room
        redirect_to admin_exam_room_path(@exam, phase: params[:phase].presence || @exam.room_phase)
    end

    def clear_seat(seat)
        submit = @exam.pset.submits.find_by(seat: seat)
        return if submit.nil?
        submit.update(seat: nil)
        flash[:notice] = "#{submit.user_name} is no longer at #{@exam.seat_label(seat)}."
    end

    def fill_seat(seat)
        submit = @exam.pset.submits.find(params[:submit_id])
        occupant = @exam.pset.submits.find_by(seat: seat)

        return if occupant == submit

        was = submit.seat

        # dragging one student onto another trades their tables: neither of
        # them leaves the room, which is what dragging looks like it does
        if occupant.present? && params[:swap].present? && was.present?
            return swap_seats(submit, occupant, was, seat)
        end

        if occupant.present? && params[:replace].blank?
            flash[:alert] = "#{@exam.seat_label(seat)} is taken by #{occupant.user_name}."
            return
        end

        Submit.transaction do
            occupant&.update!(seat: nil)
            submit.update!(seat: seat)
        end

        flash[:notice] =
            if occupant.present?
                "#{submit.user_name} replaced #{occupant.user_name} at #{@exam.seat_label(seat)}, " \
                "who is now unplaced."
            elsif was.present?
                "#{submit.user_name} moved from #{@exam.seat_label(was)} to #{@exam.seat_label(seat)}."
            else
                "#{submit.user_name} is at #{@exam.seat_label(seat)}."
            end
    rescue ActiveRecord::RecordNotUnique
        flash[:alert] = "#{@exam.seat_label(seat)} was just taken by someone else. Try again."
    end

    # Exchanges two students' tables. One of them is parked at no table for the
    # length of the transaction, because a seat is unique per exam and the two
    # updates cannot both hold it.
    def swap_seats(submit, occupant, from, to)
        Submit.transaction do
            occupant.update!(seat: nil)
            submit.update!(seat: to)
            occupant.update!(seat: from)
        end

        flash[:notice] = "#{submit.user_name} and #{occupant.user_name} swapped tables " \
                         "(#{@exam.seat_label(from)} and #{@exam.seat_label(to)})."
    end

    # Adds or removes one table from the room, refusing to remove an occupied
    # one so that a right-click cannot silently unplace a student.
    def toggle_disabled_seat(seat)
        disabled = @exam.disabled_seats

        if disabled.include?(seat)
            return disabled - [ seat ]
        end

        occupant = @exam.pset.submits.find_by(seat: seat)
        if occupant.present?
            flash[:alert] = "#{occupant.user_name} is at #{@exam.seat_label(seat)}. " \
                            "Remove them from the table before switching it off."
            return nil
        end

        disabled + [ seat ]
    end

    # Puts one more row or column along one side. Adding at the front or on the
    # left moves everything else along, which is why it is a button of its own
    # rather than typing a larger number into the dimensions.
    def add_to_room(side)
        unless Exam::ROOM_SIDES.include?(side)
            flash[:alert] = "That is not a side of the room."
            return redirect_back_to_room
        end

        if @exam.room_at_limit?(side)
            flash[:alert] = "The room is already as big as it goes."
            return redirect_back_to_room
        end

        moved = @exam.placed_submits.count if side.in?([ "front", "left" ])
        @exam.grow_room!(side)

        flash[:notice] =
            case side
            when "back"  then "Added a row at the back."
            when "right" then "Added a column on the right."
            when "front" then "Added a row at the front. Everything behind it moved back a row" +
                              (moved.to_i.positive? ? ", including #{moved} placed #{'student'.pluralize(moved)}." : ".")
            when "left"  then "Added a column on the left. Everything moved one column along" +
                              (moved.to_i.positive? ? ", including #{moved} placed #{'student'.pluralize(moved)}." : ".")
            end

        redirect_back_to_room
    end

    # Takes one row or column off a side. Refused while anybody is sitting on
    # that side: the button is disabled in that case, so this is the check for
    # the seat that was taken while the page was open.
    def remove_from_room(side)
        unless Exam::ROOM_SIDES.include?(side)
            flash[:alert] = "That is not a side of the room."
            return redirect_back_to_room
        end

        if @exam.room_at_minimum?(side)
            flash[:alert] = "A room needs at least one row and one column."
            return redirect_back_to_room
        end

        occupants = @exam.edge_occupants(side)
        if occupants.any?
            flash[:alert] = "#{occupants.map(&:user_name).to_sentence} " \
                            "#{occupants.one? ? 'is' : 'are'} sitting on that side. " \
                            "Take them off their tables first."
            return redirect_back_to_room
        end

        @exam.shrink_room!(side)

        flash[:notice] =
            case side
            when "back"  then "Removed the row at the back."
            when "right" then "Removed the column on the right."
            when "front" then "Removed the row at the front. Everything behind it moved forward a row."
            when "left"  then "Removed the column on the left. Everything moved one column along."
            end

        redirect_back_to_room
    end

    # Whether these dimensions take tables away from the room.
    def shrinking?(attrs)
        (attrs["rows"].present? && attrs["rows"] < @exam.room_rows) ||
        (attrs["cols"].present? && attrs["cols"] < @exam.room_cols)
    end

end
