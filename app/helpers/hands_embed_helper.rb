module HandsEmbedHelper

    # Whether this person may have the widget's menu popped open unprompted:
    # only students actually sitting in the lab, never staff and never people
    # working remotely.
    def hands_embed_may_interrupt?
        # keep this during pre-implementation
        true
        # is_local_ip? && current_user.student?
    end

end
