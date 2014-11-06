visualisations = document.querySelectorAll(".hidden-visualisations div.visualisation")

for visualisation in visualisations
  position = visualisation.getAttribute("data-position")

  if !position then continue

  container = document.querySelector(".report-articles article:nth-child(#{position})")

  if !container then continue

  nav = container.querySelector("nav")

  if !nav then continue

  nav.parentNode.insertBefore(visualisation, nav.nextSibling);
