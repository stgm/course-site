module EditInPlaceHelper

    #
    # render a remote checkbox form,
    #    object: any ActiveRecord object that has an id
    #    item: the object attribute name that will be toggled
    #    value: the current value of the attribute
    #    url: where to submit to
    #    block: the content of the label attached to the checkbox
    #
    def checkbox_for(object, item, value, url, **options, &block)
        id = object.class.to_s.downcase + "_" + item.to_s + "_" + object.id.to_s
        label_content = capture(&block)
        form_options = options.delete(:form) || {}

        capture do
            form_for(object, form_options.merge(url: url, data: { controller: 'toggle-form' })) do |form|
                concat hidden_field_tag(:id)
                concat form.check_box item, options.merge({ checked: value, id: "check_#{id}" })
                if label_content.present?
                    concat " <label for='check_#{id}'>".html_safe
                    concat label_content
                    concat "</label>".html_safe
                end
            end
        end
    end

    # Editing is driven by a delegated handler, so a field is a single element
    # with no handlers of its own: there is one per student in the overview.
    def edit_in_place(object, property)
        property = property.to_s
        real_object = edit_in_place_real_object_for object

        tag.div(
            real_object.send(property).to_s,
            contenteditable: true,
            data: { url: url_for(real_object), id: real_object.id, model: real_object.class.name.downcase, property: property },
            class: "in_place_editable"
        )
    end

    def edit_in_place_real_object_for(object)
        (object.is_a?(Array) && object.last.class.respond_to?(:model_name)) ? object.last : object
    end

end
