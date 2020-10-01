module GradingHelper

	def present_file_contents(filename, contents)
		if filename[-4,4] == "Form"
			format_form_contents(contents)
		else
			link_to 'd', grading_download_path(grading_submit_id: @submit.id, filename: filename), remote: false, class: 'float-right'
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
				tag.div contents.html_safe, class: 'ipynb'
			else
				CodeRay.scan(contents, filetype).div(:line_numbers => :inline).html_safe
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
					cell['source'].each do |line|
						write indent(line)
					end
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

		def write(s)
			@markdown_source << s
		end

	end

end
