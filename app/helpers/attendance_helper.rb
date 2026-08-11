module AttendanceHelper

    # A checkbox that submits itself, so staff can tick students off without
    # leaving the list.
    def toggle_checkin_form(user)
        form_for(:attendance, url: attendance_confirm_path(user_id: user.id), data: { controller: "toggle-form setting-text-form" }, class: "form-switch d-inline") do |form|
            concat(form.check_box("confirmed",
                {
                    checked: user.attendance_confirmed,
                    id: "user_#{user.id}_attend",
                    class: "form-check-input"
                }
            ))
        end
    end

end
