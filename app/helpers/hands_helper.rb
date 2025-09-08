module HandsHelper

    def get_colors_for_text(t)
        background = Digest::SHA1.hexdigest(t).slice(0, 6)
        rgbval = background.hex
        r = rgbval >> 16
        g = (rgbval & 65280) >> 8
        b = rgbval & 255
        brightness = r*0.299 + g*0.587 + b*0.114
        foreground = (brightness > 160) ? "000" : "fff"
        return "color: \##{foreground}; background-color: \##{background}"
    end

    def minutes_ago(datetime)
        ((DateTime.now - datetime.to_datetime) * 25 * 60).to_i
    end

    def suggest_prompt
        t("hands.prompts").sample
    end

    # the hands dropdown should be shown if entering a location is "required"
    def show_hands_automatically?
        is_local_ip? &&
        Settings.hands_location_bumper &&
        current_user.student? &&
        current_user.last_known_location.blank?
    end

    def render_hand(hand: nil, user: nil, provide_suggestion: false)
        if hand.nil? && user.nil?
          raise ArgumentError, "You must provide either 'hand' or 'user' argument."
        end

        if hand.present?
            locals = {
                user: hand.user,
                location: hand.location,
                waiting_since: hand.created_at,
                spoken_since: nil,
                subject: hand.subject,
                question: hand.help_question,
                suggestion: nil
            }
            render partial: "hand", locals: locals
        elsif user.present?
            suggestion = provide_suggestion && suggest_prompt || nil
            locals = {
                user: user,
                location: user.last_known_location,
                waiting_since: nil,
                spoken_since: user.last_spoken_at,
                subject: "Check in",
                question: "This student needs a check-in. #{'They\'ve never had assistance before, so be sure to welcome them to the course and ask how they\'re getting started!' if user.last_spoken_at.nil?}",
                suggestion: suggestion
            }
            render partial: "hand", locals: locals
        end
    end

    def toggle_checkin_form(user)
        form_for(:location, url: confirm_location_hands_path(user_id: user.id), data: { controller: 'toggle-form setting-text-form' }, class: 'form-switch d-inline') do |form|
                    concat(form.check_box("confirmed",
                        {
                            checked: user.location_confirmed,
                            id: "user_#{user.id}_attend",
                            class: "form-check-input"
                        }
                    ))
                    #concat(tag.label 'attend', class: "form-check-label", for: "user_#{user.id}_attend")
        end
    end

end
