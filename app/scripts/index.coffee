# Illustrations
illustrations = document.querySelectorAll(".illustrations img")
buttons = document.querySelectorAll(".illustration-buttons a")

count = 0

for button in buttons
  button.index = count

  button.onclick = ->
    index = this.index

    for i in [0..illustrations.length - 1]
      illustration = illustrations[i]
      button = buttons[i]

      illustration.style.display = if i == index then "block" else "none"
      button.className = if i == index then "circle selected" else "circle"

  count++

# Accordion tabs

neutralityTabCallback = ->
  paths = document.querySelectorAll("#map .land-group")

  for path in paths
    path.style.opacity = 0.9

genderTabCallback = ->
  activeIcons = document.querySelectorAll(".infographic-percentage img.active")

  for icon in activeIcons
    icon.style.opacity = 0.8

empowermentCallback = ->
  circles = document.querySelectorAll(".infographic-circles .circle")

  for circle in circles
    r = circle.getAttribute("data-r")

    increment = (circle, inc, time) ->
      setTimeout( ->
        circle.setAttribute("r", "#{inc}%")
      , time)

    if r
      for inc in [0..r]
        increment(circle, inc, inc * 30)

_accordionTabs = document.querySelectorAll(".accordion article")
_accordion = document.querySelector(".accordion")
accordionTabs = []
accordionCallbacks = [neutralityTabCallback, empowermentCallback, genderTabCallback, null]

# Reverse order
for tab in _accordionTabs
  accordionTabs.unshift(tab)

for i in [0..accordionTabs.length - 1]
  tab = accordionTabs[i]
  tab.closedPosition = if i == accordionTabs.length - 1 then 0 else 100 - (i + 1) * 10
  tab.openedPosition = (accordionTabs.length - 1 - i) * 10
  tab.touched = false
  tab.tabs = accordionTabs
  tab.index = i
  tab.position = undefined
  tab.opened = undefined
  tab.touchable = undefined

  tab.close = ->
    this.setPosition(this.closedPosition + "%")
    this.opened = false
    this.position = this.closedPosition

  tab.closeWithIncrement = (increment) ->
    this.setPosition(increment + "%")
    this.opened = false
    this.position = increment

  tab.open = ->
    this.setPosition(this.openedPosition + "%")
    this.opened = true
    this.position = this.openedPosition

  tab.isMobile = ->
    this.offsetWidth == _accordion.offsetWidth

  #if tab.isMobile()
  #  tab.opened = i == 0
  #else
  #  tab.opened = i == accordionTabs.length - 1

  #tab.touchable = !tab.opened
  #tab.position = if tab.opened then tab.openedPosition else tab.closedPosition

  tab.setPosition = (value) ->
    if (this.isMobile())
      this.style.bottom = value
    else
      this.style.right = value

  # Cannot be known at launch
  tab.setInitialPosition = ->
    if this.position == undefined
      if this.isMobile()
        this.opened = this.index == 0
        this.position = this.openedPosition # Inverted (first opened)
        this.touchable = this.index != accordionTabs.length - 1
      else
        this.opened = this.index == accordionTabs.length - 1
        this.position = if this.opened then this.openedPosition else this.closedPosition
        this.touchable = !this.opened

  tab.onclick = ->
    this.setInitialPosition()

    if this.opened
      return

    this.isMobile()

    if !this.openedTimes
      this.openedTimes = 0

    this.openedTimes = this.openedTimes + 1

    tabs = this.tabs

    # Position in tabs
    position = tabs.indexOf(this)

    # Close previous tabs
    for i in [0..position - 1] when i >= 0
      tabs[i].close()

    # Open current tab
    this.open()

    increment = this.openedPosition

    # Move following tabs
    count = 1
    i = position + 1

    while i < tabs.length
      tabs[i].closeWithIncrement(increment - count * 10)
      count++
      i++

    # Callback

    if this.openedTimes == 1 && accordionCallbacks[this.index]
      accordionCallbacks[this.index].call()

  tab.onmouseenter = ->
    this.setInitialPosition()

    if !this.touchable || this.touched || this.opened
      return

    this.touched = true

    position = this.position - 2
    this.setPosition(position + "%")

  tab.onmouseout = ->
    this.setInitialPosition()

    if !this.touched
      return

    this.touched = false

    this.setPosition(this.position + "%")

# Animate numbers
interval = setInterval( ->
    for i in [0..4]
      number1 = Math.floor(Math.random() * 10)
      number2 = Math.floor(Math.random() * 10)
      setPercentage("#tab#{i}", "#{number1}#{number2}")

  , 40)

# Download data

indicator1 = "P7"
indicator2 = "S3"
indicator3 = "S12"
indicator4 = "P9"

host = @settings.server.url
url = "#{host}/home/#{indicator1}/#{indicator2}/#{indicator3}/#{indicator4}"

if @settings.server.method is "JSONP"
  url += "?callback=getDataCallback"
  @processJSONP(url)
else
  @processAJAX(url, getDataCallback)

@getDataCallback = (data) ->
  clearInterval interval

  renderTable(data.rankings)

  renderNeutralityTab(data.observations1, data.percentage1)
  renderEmpowermentTab(data.observations2, data.percentage2)
  renderGenderTab(data.percentage3)
  renderPrivacyTab(data.percentage4)

# Render ranking table

renderTable = (data) ->
  tableBody = document.querySelector("table.ranking tbody")

  values = if data.values then data.values else []
  path = document.getElementById("path")?.value

  count = 0

  for value in values
    count++

    if count > 5 then break

    country = value["name"]
    area = value["area"]
    rank = value["rank"]
    index = value["index"]
    empowerment = value["EMPOWERMENT"]
    universal_access = value["UNIVERSAL_ACCESS"]
    freedom_openness = value["FREEDOM_&_OPENNESS"]
    relevant_content = value["RELEVANT_CONTENT_&_USE"]

    tr = document.createElement "tr"
    tableBody.appendChild tr

    td = document.createElement "td"
    tr.appendChild td

    flag = document.createElement "img"
    flag.className = "flag"
    flag.src = "#{path}/images/flags/#{area}.png"
    td.appendChild flag

    p = document.createElement "p"
    p.className = "country-name"
    p.innerHTML = country
    td.appendChild p

    td = document.createElement "td"
    td.setAttribute("data-title", "Rank")
    td.innerHTML = rank
    tr.appendChild td

    td = document.createElement "td"
    td.setAttribute("data-title", "Universal Access")
    tr.appendChild td
    td.innerHTML = universal_access.toFixed(2)

    td = document.createElement "td"
    td.setAttribute("data-title", "Relevant Content")
    tr.appendChild td
    td.innerHTML = relevant_content.toFixed(2)

    td = document.createElement "td"
    td.setAttribute("data-title", "Freedom And Openness")
    tr.appendChild td
    td.innerHTML = freedom_openness.toFixed(2)

    td = document.createElement "td"
    td.setAttribute("data-title", "Empowerment")
    tr.appendChild td
    td.innerHTML = empowerment.toFixed(2)

  wesCountry.table.sort.apply()

# Neutrality tab

renderNeutralityTab = (countries, percentage) ->
  setPercentage("#tab1", percentage)

  wesCountry.maps.createMap({
    container: '#map',
    "borderWidth": 0,
    borderColour: "#f93845",
    countries: countries,
    download: false,
    width: 500,
    height: 200,
    zoom: false,
    backgroundColour: "transparent",
    landColour: "#FC6A74",
    colourRange: ["#E98990", "#C20310"],
    onCountryClick: (info) ->
  })

  paths = document.querySelectorAll("#map .land-group")

  for path in paths
    path.style.opacity = 0.3

# Empowerment tab

renderEmpowermentTab = (observations, percentage) ->
  setPercentage("#tab2", percentage)

  sorter = (a, b) ->
    a_area = a.area
    b_area = b.area

    if a_area < b_area
      return -1

    if a_area > b_area
      return 1

    return 0

  observations.sort sorter

  circle = document.querySelector(".infographic-circles .model")
  container = document.getElementById("infographic-circles")

  circleSize = container.offsetWidth * 0.8 / 24

  for observation in observations
    newCircle = circle.cloneNode(true)
    newCircle.setAttribute("class", "circle")

    svg = newCircle.querySelector("svg")
    svg.setAttribute("width", circleSize)
    svg.setAttribute("height", circleSize)

    container.appendChild(newCircle)

    valueCircle = newCircle.querySelector(".circle")

    size = valueCircle.getBoundingClientRect().width
    value = observation.values[0]

    r = size * value / 100
    valueCircle.setAttribute("data-r", "#{r}")
    valueCircle.setAttribute("r", "0")

    newCircle.querySelector(".country")?.innerHTML = observation.area

# Gender tab

renderGenderTab = (percentage) ->
  setPercentage("#tab3", percentage)

  container = document.querySelector(".infographic-percentage")
  icon = document.querySelector(".infographic-icon")
  iconSrc = icon.src

  count = 1

  for row in [0..3]
    p = document.createElement "p"
    container.appendChild p

    for element in [0..24]
      img = document.createElement "img"
      img.src = iconSrc
      p.appendChild img

      if count <= percentage
        img.className = "active"

      count++

# Privacy tab

renderPrivacyTab = (percentage) ->
  setPercentage("#tab4", percentage)

  percentage = 100 - percentage

  svg = document.getElementById("world")
  pie = document.getElementById("world-pie")

  width = svg.width.baseVal.value

  cx = width / 2
  cy = width / 2
  radius = width / 2
  x1 = width / 2
  y1 = 0
  total = 100
  maxAngle = Math.abs(percentage / total * Math.PI * 2)

  for angle in [0..maxAngle] by 0.05
    increaseAngle = (angle, time) ->
      setTimeout(->
        x2 = cx + radius * Math.sin(angle)
        y2 = cy - radius * Math.cos(angle)

        big = if percentage >= 50 then 1 else 0

        d = "M " + cx + "," + cy + " L " + x1 + "," + y1 + " A " + radius + "," + radius + " 0 " + big + " 1 " + x2 + "," + y2 + " Z"
        pie.setAttribute("d", d)
      , time)

    increaseAngle(angle, angle * 150)

# Auxiliary

setPercentage = (article, percentage) ->
  labels = document.querySelectorAll("#{article} strong.percentage")

  for label in labels
    label.innerHTML = "#{percentage}%"
