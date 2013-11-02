module ApplicationHelper

	def page_done_icon(user, pset)
		if user && pset && Submit.where(:user_id => user.id, :pset_id => pset.id).count > 0
			" <span class='glyphicon glyphicon-thumbs-up'></span>".html_safe
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
							   :parse_block_html => true,
		                       :coderay_css => :class,
		                       :coderay_tab_width => 4,
		                       :enable_coderay => true,
		                       :coderay_line_numbers => nil).to_custom_html.html_safe
	end
	
	def simple_markdown(text)
		# pass public parl URL to the image converter
		# :image_prefix is defined in config/application.rb
		Kramdown::Document.new(text,
		                       :auto_ids => false,
							   :parse_block_html => true,
		                       :coderay_css => :class,
		                       :coderay_tab_width => 4,
		                       :enable_coderay => true,
		                       :coderay_line_numbers => nil).to_custom_html.html_safe
	end
	
	def title()
		(@page && @page.title) || @title
	end
	
	def form_tag_if(condition, url_for_options = {}, options = {}, &block)
		if condition
			form_tag(url_for_options, options, &block)
		else
			capture(&block)
		end
	end

	def submit_grade_link(submit)
		if submit.grade.nil?
			link_to 'grade', new_submit_grade_url(submit_id: submit.id)
		else
			link_to 'revise grade', edit_submit_grade_url(submit_id: submit.id)
		end
	end

end
