# READ MORE

articles = document.querySelectorAll(".about-articles article")
#lastParagraphs = document.querySelectorAll("article p:nth-of-type(5)")

for article in articles
  paragraph = article.querySelector("p:nth-of-type(5)")

  if !paragraph then continue

  sibling = paragraph.nextSibling

  left = 0

  while sibling
    if sibling and sibling.innerHTML then left++
    sibling = sibling.nextSibling

  if left < 4 then continue

  sibling = paragraph.nextSibling

  while sibling
    sibling.className = if sibling.className == "" then "element-hidden" else sibling.className + " element-hidden"
    sibling = sibling.nextSibling

  p = document.createElement("p")
  p.className = "text-right clear"

  paragraph.parentNode?.appendChild p

  a = document.createElement("a")
  a.innerHTML = "READ MORE <span>&#187;</span>"
  a.className = "read-more"
  p.appendChild a

  a.container = paragraph.parentNode
  a.collapsed = true

  a.onclick = (event) ->
    container = this.container

    className = if this.collapsed then "element-hidden" else "element-shown"
    newClassName = if this.collapsed then "element-shown" else "element-hidden"

    elements = container.querySelectorAll(".#{className}")

    for element in elements
      element.className = element.className.replace(className, newClassName)

    this.innerHTML = if this.collapsed then "<span>&#171;</span> READ LESS" else "READ MORE <span>&#187;</span>"
    this.collapsed = !this.collapsed

  a.open = ->
    if this.collapsed
      this.click()

  # Loop article tags
  tags = article.querySelectorAll("ul.tags li a")
  for tag in tags
    tag.readMore = a
    tag.onclick = (event) ->
      this.readMore.open()
      true
