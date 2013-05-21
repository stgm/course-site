module RubyCAS
	class Filter
		def self.unauthorized!(controller, vr = nil)
			if controller.params[:format] == "xml"
				if vr
					controller.send(:render, :xml => "<errors><error>#{vr.failure_message}</error></errors>", :status => 401)
				else
					controller.send(:head, 401)
				end
			else
				if use_gatewaying?
					controller.logger.debug "Skipping redirect to CAS because of Gatewaying."
				else
					redirect_to_cas_for_authentication(controller)
				end
			end
		end
	end
end
