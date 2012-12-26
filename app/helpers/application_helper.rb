module ApplicationHelper
	
	class Kramdown::Converter::CustomHtml < Kramdown::Converter::Html
		def convert_table(el, indent)
			el.attr['class'] = 'table'
			super
		end
		def convert_img(el, indent)
			el.attr['src'] = File.join(@options[:image_prefix], el.attr['src'])
			super
		end
	end

	def markdown(text, page_context)
		# pass public parl URL to the image converter
		# :image_prefix is defined in config/application.rb
		Kramdown::Document.new(text, :image_prefix => page_context.public_url, :coderay_tab_width => 4, :enable_coderay => true, :coderay_line_numbers => nil).to_custom_html.html_safe
	end
	
end
