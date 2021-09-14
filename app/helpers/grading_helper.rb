module GradingHelper
    def present_file_contents(filename, contents)
        if filename[-4,4] == "Form"
            format_form_contents(contents)
        else
            if contents.kind_of? ActiveStorage::Attachment
                concat link_to 'Download', 
                    rails_blob_path(contents, disposition: 'attachment'),
                    class: 'btn btn-small btn-light float-end',
                    data: { turbo: false }
                case contents.filename.extension
                when 'ipynb'
                    begin
                        tag.div(
                            simple_markdown(NBConverter.new(contents.download).run),
                            class: 'ipynb'
                        )
                    rescue
                        tag.div "No JSON found"
                    end
                when 'markdown', 'md'
                    simple_markdown(contents.download.bytes.pack("c*").force_encoding("UTF-8"))
                when 'html'
                    tag.div sanitize(contents.download), class: 'ipynb'
                when 'txt', 'sql'
                    if contents.filename.extension == 'txt'
                        simple_format(
                            contents.download.encode("UTF-8", undef: :replace, replace: '?')
                        )
                    else
                        filetype = CodeRay::FileType.fetch(contents.filename.sanitized, :text)
                        CodeRay.scan(contents.download, filetype)
                            .div(:line_numbers => :inline).html_safe
                    end
                else
                    if contents.representable?
                        image_tag contents.representation(resize_to_limit: [600,1800])
                    elsif contents.previewable?
                        image_tag contents.preview(resize_to_limit: [600,1800])
                    else
                        tag.div "Attachment is not previewable"
                    end
                end
            else
                concat link_to 'Download', grading_download_path(grading_submit_id: @submit.id, filename: filename), class: 'btn btn-small btn-light float-end', data: { turbo: false }
                filetype = CodeRay::FileType.fetch(filename, :text)
                if filename =~ /\.ipynb$/
                    begin
                        tag.div simple_markdown(NBConverter.new(contents).run), class: 'ipynb'
                    rescue
                        tag.div "No JSON found"
                    end
                elsif filetype == :text
                    simple_format(contents.encode("UTF-8", undef: :replace, replace: '?'))
                elsif filetype == :html
                    tag.div sanitize(contents), class: 'ipynb'
                else
                    CodeRay.scan(contents, filetype).div(:line_numbers => :inline).html_safe
                end
            end
        end
    end

    class NBConverter

        def initialize(source)
            @notebook = JSON(source)
            @markdown_source = ""
        end

        def run
            @notebook['cells'].each do |cell|
                case cell['cell_type']
                when 'markdown'
                    write cell['source'].join
                when 'code'
                    write fence
                    newline
                    cell['source'].each do |line|
                        write line
                    end
                    newline
                    write fence
                    newline
                    write "{:.input}"
                    newline(2)
                    # do not include outputs for now, because they might be huge
                    # cell['outputs'].select{|o| o['name']=='stdout' }.each do |output|
                    # 	output['text'].each do |line|
                    # 		write indent(line)
                    # 	end
                    # 	write "{:.output}"
                    # 	newline
                    # end
                    cell['outputs'].select{|o| o['output_type']=='error' }.each do |output|
                        write indent(output['ename'])
                        newline
                    end
                end
                newline(2)
            end
            return @markdown_source
        end

        private

        def newline(n=1)
            @markdown_source << "\n" * n
        end

        def indent(s)
            "    #{s}"
        end

        def fence
            "~~~"
        end

        def write(s)
            @markdown_source << s
        end

    end
end
