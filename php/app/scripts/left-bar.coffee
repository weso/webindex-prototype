﻿# LEFT BAR MOVEMENT

$(->
  msie6 = $.browser is "msie" and $.browser.version < 7

  leftBar = $(".left-bar")

  top = null

  if !msie6
    $(window).scroll((event) ->
      top ?= leftBar.offset().top

      # What the y position of the scroll is
      y = $(this).scrollTop()

      # Whether that's below the form
      if y >= top
        # if so, ad the fixed class
        leftBar.addClass("fixed")
      else
        # otherwise remove it
        leftBar.removeClass("fixed")
    )
)

# SCROLL MOVEMENT

$('article.text-article')
	.scrolledIntoView()
	.on('scrolledin', ->
    id = $(this).attr('id')

    a = document.querySelector("a[href='\##{id}']")

    clearActive()

    # Set current as active
    a.parentNode.className = "active"
  )
	.on('scrolledout', ->
  )

clearActive = ->
  # Remove previous active li class
  for li in document.querySelectorAll(".left-bar .tags li.active")
    li.className = ""

for li in document.querySelectorAll(".left-bar .tags li")
  li.onclick = ->
    clearActive()
    this.className = "active"
