module EditInPlaceHelper

	def best_in_place(object, property, options = {})
		property = property.to_s
		real_object = best_in_place_real_object_for object

		display_value = real_object.send(property).to_s

		tag.div(class: 'd-flex') do
			tag.div(
				display_value, {
					contenteditable: true,
					data: { url: url_for(real_object), id: real_object.id, model: real_object.class.name.downcase, property: property },
					onkeypress: 'if(event.keyCode==13) { save_in_place(this); return false }',
					onfocus: 'window.setTimeout(() => document.execCommand("selectAll", false, null))',
					onblur: 'save_in_place(this)',
					class: 'in_place_editable'
				}
			) +
			tag.div(class: "spinner-grow spinner-grow-sm collapse ml-1", role:"status") do
				tag.span('Saving...', class: "visually-hidden")
			end
		end

	end

	def best_in_place_real_object_for(object)
		(object.is_a?(Array) && object.last.class.respond_to?(:model_name)) ? object.last : object
	end

end
