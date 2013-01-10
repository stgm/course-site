module PageHelper

	def submitted_icon
		"<i class='icon-thumbs-up'></i>".html_safe if @submitted
	end

end
