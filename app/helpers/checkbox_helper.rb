module CheckboxHelper
	
	def checkbox_for(object, item, value, url, &block)
		id = object.class.to_s + "_" + item.to_s + "_" + object.id.to_s
		content = capture(&block)
		
		capture do
			form_for(object, url: url, remote: true, html: { id: "form_#{id}" }) do |form|
				concat form.hidden_field(:id)
				concat form.check_box item, { remote: true, checked: value, id: "check_#{id}", onclick: "$('#form_#{id}').trigger('submit.rails');" }
				concat " <label for='check_#{id}'>".html_safe
				# capture(&block)
				concat content
				concat "</label>".html_safe
			end
		end
	end	

end
