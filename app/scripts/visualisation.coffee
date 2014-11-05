visualisations = document.querySelectorAll(".visualisation")
expands = document.querySelectorAll(".visualisation .expand")

#maximiseVisualisation = ->
#  maximise(this)

maximiseVisualisationClick = (element) ->
  maximise(this.parentNode)

maximise = (element) ->
  expand = element.querySelector(".expand")
  expand.onclick = minimise

  button = element.querySelector("i")
  button.className = "fa fa-compress"

  anchor = element.querySelector(".expand a")
  anchor.title = "Minimise"

  element.className = element.className + " maximised"
  document.body.className = "noscroll"

  esc = element.querySelector(".esc")
  esc?.style.opacity = 1
  esc?.style.display = "block"

  setTimeout(->
    esc?.style.opacity = 0
    setTimeout(->
      element.querySelector(".esc")?.style.display = "none"
    , 1500)
  , 1500)

minimise = (element) ->
  element = document.querySelector(".visualisation.maximised")

  if !element
    return

  expand = element.querySelector(".expand")
  expand.onclick = maximiseVisualisationClick

  button = element.querySelector("i")
  button.className = "fa fa-expand"

  anchor = element.querySelector(".expand a")
  anchor.title = "Maximise"

  element.className = element.className.replace(" maximised", "")
  document.body.className = ""

  anchor = element.getAttribute("data-anchor")

  if anchor
    document.location.hash = ""
    document.location.hash = anchor

#for visualisation in visualisations
#  if visualisation.attachEvent
#    visualisation.attachEvent("ondblclick", maximiseVisualisation)
#  else
#    visualisation.addEventListener("dblclick", maximiseVisualisation, false)

for expand in expands
  expand.onclick = maximiseVisualisationClick

captureKeys = (evt) ->
  evt = evt || window.event

  if evt.keyCode == 27
    minimise()

  evt.preventDefault();

if document.attachEvent
  document.attachEvent("onkeydown", captureKeys)
else
  document.addEventListener("keydown", captureKeys, false)
