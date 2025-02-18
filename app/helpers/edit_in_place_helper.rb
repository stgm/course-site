module EditInPlaceHelper

    #
    # render a remote checkbox form,
    #    object: any ActiveRecord object that has an id
    #    item: the object attribute name that will be toggled
    #    value: the current value of the attribute
    #    url: where to submit to
    #    block: the content of the label attached to the checkbox
    #
    def checkbox_for(object, item, value, url, options = {}, &block)
        id = object.class.to_s.downcase + "_" + item.to_s + "_" + object.id.to_s
        label_content = capture(&block)
        form_options = options[:form] ||= {}

        capture do
            form_for(object, form_options.merge(url: url, remote: true)) do |form|
                concat hidden_field_tag(:id)
                concat form.check_box item, { checked: value, id: "check_#{id}", onchange: "Rails.fire(this.form, 'submit');" }
                if label_content.present?
                    concat " <label for='check_#{id}'>".html_safe
                    concat label_content
                    concat "</label>".html_safe
                end
            end
        end
    end

    def best_in_place(object, property, options = {})
        property = property.to_s
        real_object = best_in_place_real_object_for object

        display_value = real_object.send(property).to_s

        tag.div(class: "d-flex") do
            tag.div(
                display_value,
                contenteditable: true,
                data: { url: url_for(real_object), id: real_object.id, model: real_object.class.name.downcase, property: property },
                onkeypress: "if(event.keyCode==13) { this.blur(); return false }",
                onfocus: 'window.setTimeout(() => document.execCommand("selectAll", false, null))',
                onblur: "save_in_place(this)",
                class: "in_place_editable"
            ) +
            tag.div(class: "spinner-grow spinner-grow-sm collapse ms-1", role: "status") do
                tag.span("Saving...", class: "visually-hidden")
            end
        end
    end

    def best_in_place_real_object_for(object)
        (object.is_a?(Array) && object.last.class.respond_to?(:model_name)) ? object.last : object
    end

end
