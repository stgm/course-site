module SettingsHelper

	# create a remote form for saving a text setting in the Settings model
	def change_setting_form(setting_name, label)
		settings_form(setting_name) do |form|
			tag.div class:'form-group' do
				concat(tag.label label, for:"settings_#{setting_name}_input", class:'')
				concat(tag.div(class:'input-group') do
					concat(form.text_field(setting_name, {
						type:'text',
						class:'form-control',
						id: "settings_#{setting_name}_input",
						value:Settings[setting_name]
					}))
					concat(tag.div(class:'input-group-append') do tag.button 'Save', type:'submit', class:'btn btn-secondary' end)
				end)
			end
		end
	end

	# create a remote form for toggling a setting in the Settings model
	def toggle_setting_form(setting_name, label)
		settings_form(setting_name) do |form|
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
	
	def settings_form(setting_name)
		form_for(:settings, url: config_settings_path(), remote: true, html: { id: "settings_#{setting_name}_form" }) do |form|
			yield form
		end
	end

end
