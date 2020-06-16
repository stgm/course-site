module CheckboxHelper

	#
	# render a remote checkbox form,
	#    object: any ActiveRecord object that has an id
	#    item: the object attribute name that will be toggled
	#    value: the current value of the attribute
	#    url: where to submit to
	#    block: the content of the label attached to the checkbox
	#
	def checkbox_for(object, item, value, url, &block)
		id = object.class.to_s.downcase + "_" + item.to_s + "_" + object.id.to_s
		label_content = capture(&block)
		
		capture do
			form_for(object, url: url, remote: true, html: { id: "form_#{id}" }) do |form|
				concat hidden_field_tag(:id)
				concat form.check_box item, { remote: true, checked: value, id: "check_#{id}", onclick: "Rails.fire(document.querySelector('#form_#{id}'), 'submit');" }
				concat " <label for='check_#{id}'>".html_safe
				concat label_content
				concat "</label>".html_safe
			end
		end
	end	

end
