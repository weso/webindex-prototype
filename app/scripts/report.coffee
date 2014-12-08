visualisations = document.querySelectorAll(".hidden-visualisations div.visualisation")

for visualisation in visualisations
  anchor = visualisation.getAttribute("data-anchor")

  if anchor
    wrapper = document.querySelector(".visualisation-wrapper[data-visualisation='#{anchor}']")
    if wrapper
      wrapper.appendChild(visualisation)
      continue

  position = visualisation.getAttribute("data-position")

  if !position then continue

  container = document.querySelector(".report-articles article:nth-child(#{position})")

  if !container then continue

  nav = container.querySelector("nav")

  if !nav then continue

  nav.parentNode.insertBefore(visualisation, nav.nextSibling);

# Ranking table

rankingSection = document.querySelector("section.ranking-table")
rankingTable = rankingSection.querySelector("table")
viewMore = rankingSection.querySelector("a.ranking-view-more")
if rankingTable and viewMore
  viewMore.onclick = (event) ->
    opened = if rankingTable.opened then rankingTable.opened else false
    opened = !opened
    rankingTable.opened = opened
    rankingTable.className = if opened then "report-ranking opened" else "report-ranking"
    this.innerHTML = if opened then "<span>&#171;</span> VIEW LESS" else "VIEW MORE <span>&#187;</span>"

wrapper = document.querySelector(".ranking-wrapper")
if wrapper
  wrapper.appendChild(rankingSection)
  rankingSection?.style?.display = "block"
else
  rankingSection?.style?.display = "none"
