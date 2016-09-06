# This code makes sure that video-js elements are unloaded and loaded
# on page changes done through rails's turbolinks.

change = ->
    for player in document.getElementsByClassName 'video-js'
        videojs player

before_change = ->
    for player in document.getElementsByClassName 'video-js'
        video = videojs player
        video.dispose()

$(document).on('page:before-change', before_change)
$(document).on('page:change', change)



$(document).on('turbolinks:load', MathJax.Hub.Typeset)
