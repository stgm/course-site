module SettingsHelper

	# create a remote form for toggling a setting in the Settings model
	def toggle_setting_form(setting_name, label)
		form_for(:settings, url: config_settings_path(), remote: true, html: { id: "settings_#{setting_name}_form" }) do |form|
			tag.div class:'form-group' do
				tag.div class:'form-check' do
					concat(form.check_box(setting_name,
						{
							remote: true,
							checked: Settings[setting_name],
							id: "settings_#{setting_name}_check",
							class: "form-check-input",
							onclick: "$('#settings_#{setting_name}_form').trigger('submit.rails');"
						}
					))
					concat(tag.label label, class:'form-check-label', for:"settings_#{setting_name}_check")
				end
				
			end
		end
	end
	
end
