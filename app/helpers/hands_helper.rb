module HandsHelper

	def get_colors_for_text(t)
		background = Digest::SHA1.hexdigest(t).slice(0,6)
		rgbval = background.hex
		r = rgbval >> 16
		g = (rgbval & 65280) >> 8
		b = rgbval & 255
		brightness = r*0.299 + g*0.587 + b*0.114
		foreground = (brightness > 160) ? "000" : "fff"
		return "color: \##{foreground}; background-color: \##{background}"
	end
	
	def minutes_ago(datetime)
		((DateTime.now - datetime.to_datetime) * 25 * 60).to_i
	end

end
