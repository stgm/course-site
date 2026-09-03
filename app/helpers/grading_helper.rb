module GradingHelper

    def present_file_contents(filename, contents)
        if filename[-4, 4] == "Form"
            format_form_contents(contents)
        else
            if contents.kind_of? ActiveStorage::Attachment
                if contents.blob.byte_size == 0
                    return tag.div "This file was 0 bytes when uploaded"
                end
                case contents.filename.extension
                when "ipynb"
                    begin
                        downloaded = contents.download
                        tag.div(
                            render_markdown(NotebookConverter.new(downloaded).run, single_dollar_math: true),
                            class: "ipynb"
                        )
                    rescue
                        tag.div tag.p("No valid JSON found in notebook file, showing first 100 characters if available: ") +
                                tag.pre(downloaded && downloaded[0, 100])
                    end
                when "markdown", "md"
                    render_markdown(contents.download.bytes.pack("c*").force_encoding("UTF-8"))
                when "html"
                    tag.div sanitize(contents.download), class: "ipynb"
                when "txt", "sql", "c", "py", "karel"
                    if contents.blob.byte_size > 1.megabyte
                        tag.div "Attachment is weirdly large"
                    elsif contents.filename.extension == "txt"
                        simple_format(
                            contents.download.encode("UTF-8", undef: :replace, replace: "?")
                        )
                    else
                        filetype = CodeRay::FileType.fetch(contents.filename.sanitized, :text)
                        begin
                            c = contents.download
                        rescue ActiveStorage::FileNotFoundError => e
                            return tag.div "ERROR: File not found in storage"
                        end
                        CodeRay.scan(c, filetype)
                            .div(line_numbers: :inline).html_safe
                    end
                else
                    if contents.content_type == "application/pdf"
                        tag.iframe src: rails_storage_proxy_path(contents)
                    elsif contents.representable?
                        image_tag rails_storage_proxy_path(contents.representation(resize_to_limit: [ 600, 1800 ]))
                    elsif contents.previewable?
                        image_tag rails_storage_proxy_path(contents.preview(resize_to_limit: [ 600, 1800 ]))
                    else
                        tag.div "Attachment is not previewable"
                    end
                end
            else
                concat link_to "Download", grading_download_path(grading_submit_id: @submit.id, filename: filename), class: "btn btn-small btn-light float-end", data: { turbo: false }
                filetype = CodeRay::FileType.fetch(filename, :text)
                if filename =~ /\.ipynb$/
                    begin
                        tag.div render_markdown(NotebookConverter.new(contents).run, single_dollar_math: true), class: "ipynb"
                    rescue
                        tag.div "No JSON found"
                    end
                elsif filetype == :text
                    simple_format(contents.encode("UTF-8", undef: :replace, replace: "?"))
                elsif filetype == :html
                    tag.div sanitize(contents), class: "ipynb"
                else
                    CodeRay.scan(contents, filetype).div(line_numbers: :inline).html_safe
                end
            end
        end
    end

end
