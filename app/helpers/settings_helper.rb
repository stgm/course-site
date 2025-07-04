module SettingsHelper

    # create a remote form for saving a text setting in the Settings model
    def change_setting_form(setting_name, label, **options)
        label_position = options.delete(:label_position) || :above
        validate = options.delete(:validate) || false
        form_classes = validate && 'was-validated' || ''
        settings_form(setting_name, class: form_classes) do |form|
            tag.div class: " mb-2" do
                concat(tag.label label, for: "settings_#{setting_name}_input", class: "small") if label_position == :above
                concat(tag.div(class: "input-group") do
                    concat(form.text_field(setting_name, options.merge({
                        type: "text",
                        class: "form-control",
                        id: "settings_#{setting_name}_input",
                        value: Settings.send("#{setting_name}")
                    })))
                    concat(tag.button "Save", type: "submit", class: "btn btn-primary")
                end)
                concat(tag.label label, for: "settings_#{setting_name}_input", class: "small") if label_position == :below
            end
        end
    end

    # create a remote form for toggling a setting in the Settings model
    def toggle_setting_form(setting_name, label)
        settings_form(setting_name) do |form|
            tag.div class: " mb-1" do
                tag.div class: "form-check" do
                    concat(form.check_box(setting_name,
                        {
                            checked: Settings.send("#{setting_name}"),
                            id: "settings_#{setting_name}_check",
                            class: "form-check-input"
                        }
                    ))
                    concat(tag.label label, class: "form-check-label", for: "settings_#{setting_name}_check")
                end
            end
        end
    end

    def settings_form(setting_name, **options)
        form_classes = options.delete(:class) || ''
        form_for(:settings, url: admin_site_settings_path(), data: { controller: 'toggle-form setting-text-form' }, class: form_classes) do |form|
            yield form
        end
    end

end
