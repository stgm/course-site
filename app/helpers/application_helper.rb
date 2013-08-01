module ApplicationHelper

	def page_done_icon(user, pset)
		if user && pset && Submit.where(:user_id => user.id, :pset_id => pset.id).count > 0
			" <i class='icon-thumbs-up'></i>".html_safe
		else
			""
		end
	end

	def markdown(text, page_context)
		# pass public parl URL to the image converter
		# :image_prefix is defined in config/application.rb
		Kramdown::Document.new(text,
		                       :auto_ids => false,
		                       :asset_prefix => page_context.public_url,
		                       :cdn_prefix => Course.cdn,
		                       :coderay_css => :class,
		                       :coderay_tab_width => 4,
		                       :enable_coderay => true,
		                       :coderay_line_numbers => nil).to_custom_html.html_safe
	end
	
	def title()
		(@page && @page.title) || @title
	end

end
