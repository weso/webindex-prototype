global = this
global.options = {}
global.selectorDataReady = {}
global.selections = {
  indicator: null,
  countries: null,
  year: null
}
global.maxTableRows = 7
global.continents = {}

################################################################################
#                                 INIT SELECTORS
################################################################################




################################################################################
#                                 PAGE STATE
################################################################################

setPageStateful = ->
  wesCountry.stateful.start({
    init: (parameters, selectors) ->
      if settings.debug then console.log "init"
    urlChanged: (parameters, selectors) ->
      url = wesCountry.stateful.getFullURL()

      if settings.debug then console.log url

    elements: [
      {
        name: "indicator",
        selector: "#indicator-select",
        onChange: (index, value, parameters, selectors) ->
          if settings.debug then console.log "indicator:onChange index:#{index} value:#{value}"

          global.selections.indicator = value
          updateInfo()

          # Show republish notification
          option = selectors["#indicator-select"]?.options?[index]
          republish = option.getAttribute("data-republish")
          republish = republish == "true"

          document.getElementById("notifications")?.style?.display = if republish then "none" else "block"
      },
      {
        name: "time",
        selector: global.options.timeline,
        onChange: (index, value, parameters, selectors) ->
          if settings.debug then console.log "year:onChange index:#{index} value:#{value}"

          global.selections.year = value
          updateInfo()
      },
      {
        name: "country",
        selector: global.options.countrySelector,
        value: "ALL",
        onChange: (index, value, parameters, selectors) ->
          if settings.debug then console.log "country:onChange index:#{index} value:#{value}"

          global.selections.countries = value
          updateInfo()
      }
    ]
  })

################################################################################
#                             SERVER COMMUNICATION
################################################################################

getSelectorData = ->
  getIndicators()
  getYears()
  getCountries()

# Indicators

getIndicators = () ->
  host = @settings.server.url
  url = "#{host}/indicators/INDEX"

  if @settings.server.method is "JSONP"
    url += "?callback=getIndicatorsCallback"
    @processJSONP(url)
  else
    @processAJAX(url, getYearsCallback)

@getIndicatorsCallback = (data) ->
  indicators = []

  if data.success then indicators = data.data

  setIndicatorOptions(document.getElementById("indicator-select"), indicators, 0)

  global.selectorDataReady.indicatorSelector = true
  checkSelectorDataReady()

setIndicatorOptions = (select, element, level) ->
  republish = if element.republish then element.republish else false
  type = if element.type then element.type else "Primary"

  option = document.createElement("option")
  option.value = element.indicator
  option.setAttribute("data-republish", republish)
  option.setAttribute("data-type", type)

  space = Array(level * 3).join '&nbsp'
  option.innerHTML = space + element.name
  select.appendChild(option)

  for child in element.children
    setIndicatorOptions(select, child, level + 1)

# Years

getYears = () ->
  host = @settings.server.url
  url = "#{host}/years/array"

  if @settings.server.method is "JSONP"
    url += "?callback=getYearsCallback"
    @processJSONP(url)
  else
    @processAJAX(url, getYearsCallback)

@getYearsCallback = (data) ->
  years = []

  if data.success then years = data.data.sort()

  # Timeline

  global.options.timeline = wesCountry.selector.timeline({
    container: '#timeline',
    maxShownElements: 10,
    elements: years
  })

  global.selectorDataReady.timeline = true
  checkSelectorDataReady()

# Countries

getCountries = () ->
  host = @settings.server.url
  url = "#{host}/areas/continents"

  if @settings.server.method is "JSONP"
    url += "?callback=getCountriesCallback"
    @processJSONP(url)
  else
    @processAJAX(url, getYearsCallback)

@getCountriesCallback = (data) ->
  countries = []

  if data.success then countries = data.data

  countries.unshift({
    "short_name": "All countries",
    iso3: "ALL"
  })

  # Country selector

  global.options.countrySelector = new wesCountry.selector.basic({
    data: countries,
    selectedItems: ["ALL"],
    maxSelectedItems: global.maxTableRows,
    labelName: "short_name",
    valueName: "iso3",
    childrenName: "countries",
    autoClose: true,
    selectParentNodes: false,
    beforeChange: (selectedItems, element) ->
      if !global.options.countrySelector
        return

      if selectedItems.length == 0
        global.options.countrySelector.select("ALL")
      else if element.code == "ALL"
        if selectedItems.length > 1
          global.options.countrySelector.clear()
          global.options.countrySelector.select("ALL")
      else if selectedItems.search("ALL") != -1
        global.options.countrySelector.unselect("ALL")

    sort: false })

  document.getElementById("country-selector").appendChild(global.options.countrySelector.render())

  global.selectorDataReady.countries = true
  checkSelectorDataReady()

checkSelectorDataReady = ->
  if global.selectorDataReady.timeline and global.selectorDataReady.countries and global.selectorDataReady.indicatorSelector
    setPageStateful()

# Observations

getObservations = (indicator, countries, year) ->
  host = @settings.server.url
  url = "#{host}/visualisations/#{indicator}/#{countries}/#{year}"

  if @settings.server.method is "JSONP"
    url += "?callback=getObservationsCallback"
    @processJSONP(url)
  else
    @processAJAX(url, getObservationsCallback)

@getObservationsCallback = (data) ->
  if !data.success then return

  observations = data.data
  global.continents = data.data.continents
  renderCharts(observations)
  renderTable(observations)
  renderBoxes(observations)

# Update information

updateInfo = () ->
  year = global.selections.year
  countries = global.selections.countries
  indicator = global.selections.indicator

  if settings.debug then console.log "year: #{year} countries: #{countries} indicator: #{indicator}"

  if !year or !countries or !indicator then return

  getObservations(indicator, countries, year)

  document.getElementById("indicator")?.innerHTML = indicator.replace(/_/g, " ")
  document.getElementById("year")?.innerHTML = year

renderContinentLegend = (data, options, container, getContinents, getContinentColour) ->
  continents = getContinents(options)

  ul = document.createElement "ul"
  container.appendChild ul

  for continent in continents
    code = continent.code
    colour = getContinentColour(options, continent)
    name = data.continents[code]

    li = document.createElement "li"
    ul.appendChild li

    circle = document.createElement "div"
    circle.className = "circle"
    circle.style.backgroundColor = colour
    li.appendChild circle

    span = document.createElement "span"
    span.className = "continent"
    li.appendChild span

    span.innerHTML = name

renderCharts = (data) ->
  mapContainer = "#map"
  barContainer = "#country-bars"
  lineContainer = "#lines"
  rankingContainer = "#ranking-chart"

  mapView = "#map-view"
  countryView = "#country-view"

  if global.selections.countries == "ALL"
    # Show map view
    document.querySelector(mapView)?.style.display = 'block'
    # Hide country view
    document.querySelector(countryView)?.style.display = 'none'

    view = document.querySelector(mapView)
    # Map

    global.observations = data.observations

    renderMap()

    # Ranking

    rankingContainerDiv = document.querySelector(rankingContainer)
    rankingContainerDiv?.innerHTML = ""

    rankingWrapper = document.createElement "div"
    rankingWrapper.className = "wrapper"
    rankingContainerDiv?.appendChild rankingWrapper

    rankingLegend = document.createElement "div"
    rankingLegend.className = "legend"
    rankingContainerDiv?.appendChild rankingLegend

    getContinentColour = (options, element, index) ->
      pos = 0

      switch element.continent
        when "ECS"
          pos = 0
        when "NAC"
          pos = 5
        when "LCN"
          pos = 1
        when "AFR"
          pos = 2
        when "SAS"
          pos = 3
        when "EAS"
          pos = 6
        when "MEA"
          pos = 4

      return options.serieColours[pos]

    getLegendElements = (options) ->
      elements = []
      series = options.series
      length = series.length

      for serie in series
        continent = serie.continent

        if elements.indexOf(continent) == -1
          elements.push(continent)

      elements = elements.sort()

      length = elements.length
      range = [0..length - 1]

      for i in range
        elements[i] = {
          code: elements[i],
          continent: elements[i]
        }

      return elements

    options = {
      maxRankingRows: 10,
      margins: [4, 0, 1, 0],
      container: rankingWrapper,
      chartType: "ranking",
      rankingElementShape: "square",
      rankingDirection: "HigherToLower",
      sortSeries: true,
      mean: {
        show: true,
        margin: 10,
        stroke: 1
      },
      median: {
        show: true,
        margin: 10,
        stroke: 1
      },
      xAxis: {
        title: "",
        colour: "#ccc",
        "font-family": "'Kite One', sans-serif",
        "font-size": "14px"
      },
      yAxis: {
        margin: 1,
        title: "",
        "font-family": "'Kite One', sans-serif",
        "font-size": "12px"
      },
      legend: {
        show: false
      },
      serieColours: ["#0489B1", "#088A68", "#FF8000", "#DBA901", "#642EFE", "#795227", "#FA5858"],
      valueOnItem: {
        "font-family": "Helvetica",
        "font-colour": "#fff",
        "font-size": "11px",
      },
      width: view.offsetWidth,
      height: view.offsetHeight,
      series: data.secondVisualisation,
      getName: (serie) ->
        serie.code
      getElementColour: getContinentColour
      getLegendElements: getLegendElements
      events: {
        onclick: (info) ->
          code = info["data-code"]
          global.options.countrySelector.select(code)
          global.options.countrySelector.refresh()
        onmouseover: (info) ->
          chartTooltip(info, global)
      }
    }

    # Chart
    wesCountry.charts.chart options

    # Legend
    renderContinentLegend(data, options, rankingLegend, getLegendElements, getContinentColour)
  else
    # Hide map view
    document.querySelector(mapView)?.style.display = 'none'
    # Show country view
    document.querySelector(countryView)?.style.display = 'block'

    document.querySelector(barContainer)?.innerHTML = ""

    view = document.querySelector(countryView)

    # Bar
    options = {
      container: barContainer,
      chartType: "bar",
      legend: {
        show: false
      },
      margins: [8, 1, 0, 2.5],
      yAxis: {
        margin: 2,
        title: ""
      },
      valueOnItem: {
        show: true
      },
      xAxis: {
        values: [],
        title: ""
      },
      groupMargin: 0,
      series: data.observations,
      mean: {
        show: true
      },
      median: {
        show: true
      },
      width: view.offsetWidth,
      height: view.offsetHeight,
      serieColours: wesCountry.makeGradientPalette(["#005475",
                                                    "#1B4E5A",
                                                    "#1B7A65",
                                                    "#83C04C",
                                                    "#E5E066"
                                                    ], data.bars.length),
      getElementColour: (options, element, index) ->
        rank = if element.ranked then element.ranked - 1 else index
        rank = if rank >= 0 and rank < options.serieColours.length then rank else index

        colour = options.serieColours[rank]

        # if not selected then colour is set lighter
        colour = if element.selected then colour else wesCountry.shadeColour(colour, 0.5)

        return colour
      events: {
        onclick: (info) ->
          code = info["data-code"]
          global.options.countrySelector.select(code)
          global.options.countrySelector.refresh()
        onmouseover: (info) ->
          chartTooltip(info, global)
      }
      getName: (serie) ->
        serie["short_name"]
    }

    wesCountry.charts.chart options

    # Line chart
    document.querySelector(lineContainer)?.innerHTML = ""

    options = {
      container: lineContainer,
      chartType: "line",
      margins: [5, 15, 5, 1],
      groupMargin: 0,
      yAxis: {
        title: ""
      },
      xAxis: {
        title: "",
        values: if data.years then data.years else []
      },
      series: if data.secondVisualisation then data.secondVisualisation else [],
      width: view.offsetWidth,
      height: view.offsetHeight,
      valueOnItem: {
        show: false
      },
      vertex: {
        show: true
      },
      serieColours: ["#FF9900", "#E3493B", "#23B5AF", "#336699", "#FF6600", "#931FC4", "#795227"]
      events: {
        onclick: (info) ->
          code = info["data-code"]
          global.options.countrySelector.select(code)
          global.options.countrySelector.refresh()
        onmouseover: (info) ->
          chartTooltip(info, global)
      },
      getName: (serie) ->
        serie["short_name"] || serie["area_name"]
    }

    wesCountry.charts.chart options

  # Bar chart

  barContainer = "#bars"
  document.querySelector(barContainer)?.innerHTML = ""
  options = {
    container: barContainer,
    chartType: "bar",
    legend: {
      show: false
    },
    margins: [8, 0, 20, 0],
    yAxis: {
      margin: 0,
      title: "",
      tickColour: "none",
      "font-colour": "none"
    },
    valueOnItem: {
      show: true
    },
    xAxis: {
      values: [],
      title: ""
    },
    groupMargin: 0,
    series: data.bars,
    mean: {
      show: true
    },
    median: {
      show: true
    },
    serieColours: wesCountry.makeGradientPalette(["#005475",
                                                  "#1B4E5A",
                                                  "#1B7A65",
                                                  "#83C04C",
                                                  "#E5E066"
                                                  ], data.bars.length),
    getElementColour: (options, element, index) ->
      colour = options.serieColours[index]

      # if not selected then colour is set lighter
      colour = if element.selected then colour else wesCountry.shadeColour(colour, 0.3)

      return colour
    events: {
      onclick: (info) ->
        code = info["data-code"]
        global.options.countrySelector.select(code)
        global.options.countrySelector.refresh()
      onmouseover: (info) ->
        chartTooltip(info, global)
    }
    getName: (element) ->
      element.code
  }

  wesCountry.charts.chart options

  # Window resize

  if window.attachEvent
    window.attachEvent("onresize", resize)
  else
    window.addEventListener("resize", resize, false)

  resize = ->
    #createMap()

renderMap = ->
  mapContainer = "#map > div.chart"
  document.querySelector(mapContainer)?.innerHTML = ""

  map = wesCountry.maps.createMap({
    container: mapContainer,
    borderWidth: 1.5,
    landColour: "#dcdcdc",
    borderColour: "#fff",
    backgroundColour: "none",
    countries: global.observations,
    #width: view.offsetWidth,
    #height: view.offsetHeight,
    colourRange: ["#E5E066", "#83C04C", "#1B7A65", "#1B4E5A", "#005475"],
    onCountryClick: (info) ->
      code = info.iso3
      global.options.countrySelector.select(code)
      global.options.countrySelector.refresh()
    getValue: (country) ->
      if country.values || country.values.length > 0 then country.values[0] else country.value
    onCountryOver: (info, visor) ->
      if (visor)
        visor.innerHTML = '';

        code = info["data-code"]

        if !code then return

        _value = info.value
        republish = if info["data-republish"] then info["data-republish"] else false
        _value = getValue(_value, republish)

        value = document.createElement('div')
        value.innerHTML = _value
        value.className = 'value'
        visor.appendChild(value)

        country = document.createElement('div')
        country.className = 'country'
        visor.appendChild(country)

        ranked = document.createElement('div')
        rankedValue = if info["data-ranked"] then info["data-ranked"] else ""
        ranked.innerHTML = rankedValue
        ranked.className = 'ranking'
        country.appendChild(ranked)

        flag = document.createElement "flag"
        flag.className = "flag"
        country.appendChild(flag)

        img = document.createElement "img"
        path = document.getElementById("path").value
        img.src = "#{path}/images/flags/#{code}.png"
        flag.appendChild(img)

        name = document.createElement "p"
        name.className = "name"
        name.innerHTML = info["data-short_name"]
        country.appendChild name

        name = document.createElement "p"
        name.className = "continent"
        continent = info["data-continent"]
        if continent then continent = global.continents[continent]
        name.innerHTML = continent
        country.appendChild name
  })

renderTable = (data) ->
  observations = data.observations

  table = document.querySelector("#ranking")
  path = document.getElementById("path")?.value

  tbodies = document.querySelectorAll("#ranking > tbody")
  for tbody in tbodies
    table.removeChild tbody

  count = 0

  for observation in observations
    count++
    code = observation.code
    name = observation.short_name
    rank = if observation.ranked then observation.ranked else count
    value = if observation.values && observation.values.length > 0 then observation.values[0] else observation.value
    republish = if observation.republish then observation.republish else false
    value = getValue(value, republish)
    previousValue = observation.previous_value
    extraInfo = observation.extra

    continent = ""

    if observation.continent
      continent = observation.continent
      continent = global.continents[continent]

    if previousValue
      tendency = previousValue.tendency

    tbody = document.createElement "tbody"
    table.appendChild tbody

    tr = document.createElement "tr"
    tbody.appendChild tr

    tbody.code = code
    tbody.onclick = ->
      code = this.code
      global.options.countrySelector.select(code)
      global.options.countrySelector.refresh()

    if count > global.maxTableRows
      tbody.className = "to-hide"

    td = document.createElement "td"
    td.setAttribute("data-title", "Rank")
    td.setAttribute("rowspan", "2")
    td.className = "big-number"
    tr.appendChild td

    td.innerHTML = rank

    td = document.createElement "td"
    td.setAttribute("data-title", "Country")
    tr.appendChild td

    img = document.createElement "img"
    img.className = "flag"
    img.src = "#{path}/images/flags/#{code}.png"
    td.appendChild img

    span = document.createElement "span"
    span.innerHTML = name
    td.appendChild span

    td = document.createElement "td"
    td.setAttribute("data-title", "Continent")
    tr.appendChild td

    td.innerHTML = continent

    td = document.createElement "td"
    td.setAttribute("data-title", "Value")
    tr.appendChild td

    td.innerHTML = "<div><p>value</p> #{value}</div>"

    # Extra info

    globalRank = extraInfo.rank
    universalAccess = extraInfo["UNIVERSAL_ACCESS"].toFixed(2)
    freedomOpenness = extraInfo["FREEDOM_AND_OPENNESS"].toFixed(2)
    relevantContent = extraInfo["RELEVANT_CONTENT_AND_USE"].toFixed(2)
    empowerment = extraInfo["EMPOWERMENT"].toFixed(2)

    tr = document.createElement "tr"
    tbody.appendChild tr

    td = document.createElement "td"
    td.setAttribute("colspan", "3")
    tr.appendChild td

    extraTable = document.createElement "table"
    extraTable.className = "extra-table"
    td.appendChild extraTable

    # header

    extraTheader = document.createElement "thead"
    extraTable.appendChild extraTheader

    tr = document.createElement "tr"
    extraTheader.appendChild tr

    th = document.createElement "th"
    th.setAttribute("data-title", "Web Index Rank")
    tr.appendChild th
    th.innerHTML = "Web Index Rank"

    th = document.createElement "th"
    th.setAttribute("data-title", "Universal Access")
    tr.appendChild th
    th.innerHTML = "Universal Access"

    th = document.createElement "th"
    th.setAttribute("data-title", "Relevant Content")
    tr.appendChild th
    th.innerHTML = "Relevant Content"

    th = document.createElement "th"
    th.setAttribute("data-title", "Freedom And Openness")
    tr.appendChild th
    th.innerHTML = "Freedom And Openness"

    th = document.createElement "th"
    th.setAttribute("data-title", "Empowerment")
    tr.appendChild th
    th.innerHTML = "Empowerment"

    # body

    extraTbody = document.createElement "tbody"
    extraTable.appendChild extraTbody

    tr = document.createElement "tr"
    extraTbody.appendChild tr

    td = document.createElement "td"
    td.setAttribute("data-title", "Web Index Rank")
    tr.appendChild td

    td.innerHTML = globalRank

    td = document.createElement "td"
    td.setAttribute("data-title", "Universal Access")
    tr.appendChild td

    td.innerHTML = universalAccess

    td = document.createElement "td"
    td.setAttribute("data-title", "Relevant Content")
    tr.appendChild td

    td.innerHTML = relevantContent

    td = document.createElement "td"
    td.setAttribute("data-title", "Freedom And Openness")
    tr.appendChild td

    td.innerHTML = freedomOpenness

    td = document.createElement "td"
    td.setAttribute("data-title", "Empowerment")
    tr.appendChild td

    td.innerHTML = empowerment

  if count > global.maxTableRows
    tbodies = table.querySelectorAll(".to-hide")

    for tbody in tbodies
      tbody.className = "hidden"

    tbody = document.createElement "tbody"
    tbody.className = "tbody-view-more"
    table.appendChild tbody

    tr = document.createElement "tr"
    tbody.appendChild tr

    td = document.createElement "td"
    td.colSpan = 4
    td.className = "view-more"
    tr.appendChild td

    a = document.createElement "a"
    a.innerHTML = "View more"
    td.appendChild a

    a.collapsed = true
    a.table = table

    a.onclick = ->
      collapsed = this.collapsed
      this.collapsed = !collapsed

      className = if collapsed then "hidden" else "shown"
      newClassName = if collapsed then "shown" else "hidden"
      text = if collapsed then "View less" else "View more"

      this.innerHTML = text

      rows = this.table.querySelectorAll("tbody.#{className}")

      for row in rows
        row.className = newClassName

renderBoxes = (data) ->
  mean = data.mean
  median = data.median
  higher = data.higher["short_name"]
  lower = data.lower["short_name"]

  higherArea = data.higher.area
  lowerArea = data.lower.area

  document.getElementById("mean")?.innerHTML = mean.toFixed(2);
  document.getElementById("median")?.innerHTML = median.toFixed(2);

  higherContainer = document.getElementById("higher")
  if higherContainer
    higherContainer.innerHTML = higher

    higherContainer.onclick = ->
      global.options.countrySelector.select(higherArea)
      global.options.countrySelector.refresh()

  lowerContainer = document.getElementById("lower")
  if lowerContainer
    lowerContainer.innerHTML = lower

    lowerContainer.onclick = ->
      global.options.countrySelector.select(lowerArea)
      global.options.countrySelector.refresh()

# Script load

setTimeout(->
            getSelectorData()
, @settings.elapseTimeout)

# Chart selector

chartSelectors = document.querySelectorAll(".tabs ul[data-selector] li")

for li in chartSelectors
  li.onclick = ->
    parent = this.parentNode

    # Remove selected class
    lis = parent.querySelectorAll("li")

    for li in lis
      li.className = ""

    this.className = "selected"

    # Hide / Show
    blockSelector = parent.getAttribute("data-selector")
    elementSelector = this.getAttribute("data-selector")

    # Hide all
    blocks = document.querySelectorAll(".#{blockSelector} > div")

    for block in blocks
      block.style.display = 'none'

    # Show
    blocks = document.querySelectorAll(".#{blockSelector} > div.#{elementSelector}")

    for block in blocks
      block.style.display = 'block'

    info = this.getAttribute("data-info")

    if info && info == "map"
      renderMap()

################################################################################
#                                FIX LEFT BAR
################################################################################

msie6 = $.browser is "msie" and $.browser.version < 7

selectBar = $(".select-bar")

top = null

if !msie6
  $(window).scroll((event) ->
    firstHeader = document.querySelector(".select-box header")
    top ?= selectBar.offset().top + firstHeader.offsetHeight

    # What the y position of the scroll is
    y = $(this).scrollTop()

    # Whether that's below the form
    if y >= top
      if !selectBar.collapsed
        setBoxesInitialPosition()
        # if so, add the class
        selectBar.addClass("fixed")
        setBoxesPosition()
        selectBar.collapsed = true
    else
      # otherwise remove it
      selectBar.removeClass("fixed")
      selectBar.collapsed = false
  )

setBoxesInitialPosition = ->
  boxes = document.querySelectorAll(".select-box")

  for box in boxes
    top = box.offsetTop
    box.style.top = "#{top}px"

setBoxesPosition = ->
  # Set boxes position
  boxes = document.querySelectorAll(".select-box")

  previousTop = 0

  for box in boxes
    headerHeight = box.querySelector("header").offsetHeight
    top = previousTop - headerHeight

    ###
    box.collapsedTop = top
    box.uncollapsedTop = previousTop

    box.onmouseover = ->
      top = this.uncollapsedTop
      this.style.top = "#{top}px"

    box.onmouseout = ->
      top = this.collapsedTop
      this.style.top = "#{top}px"
    ###
    box.style.top = "#{top}px"

    previousTop = top + box.offsetHeight

################################################################################
#                               COLLAPSABLE BOXES
################################################################################

collapsables = document.querySelectorAll(".collapsable")

for collapsable in collapsables
  button = collapsable.querySelector(".button")
  if !button then continue

  collapsableSection = collapsable.querySelector("section")
  if ! collapsableSection then continue

  button.collapsed = false
  button.container = collapsable

  button.onclick = ->
    this.collapsed = !this.collapsed

    container = this.container
    containerClass = container.className
    container.className = if this.collapsed then containerClass + " collapsed"  else containerClass.replace(" collapsed", "")
    this.className = if this.collapsed then "button fa fa-toggle-off" else "button fa fa-toggle-on"

################################################################################
#                               CHART TOOLTIP
################################################################################

chartTooltip = (info, global) ->
  path = document.getElementById('path').value
  value = info["data-values"]
  republish = if info["data-republish"] then info["data-republish"] == "true" else false
  value = getValue(value, republish)
  ranked = info["data-ranked"]
  code = info["data-area"]
  name = info["data-area_name"]
  time = info["data-year"]

  continent = ""

  if info["data-continent"]
    continent = info["data-continent"]
    continent = global.continents[continent]

  flagSrc = "#{path}/images/flags/#{code}.png"

  tooltipHeader = String.format('<div class="tooltip-header"><img src="{0}" /><div class="title"><p class="countryName">{1}</p><p class="continentName">{2}</p></div></div>', flagSrc, name, continent)
  tooltipBody = String.format('<div class="tooltip-body"><p class="ranking">{0}</p><p class="time">{1}</p><p class="value">{2}</p></div>', ranked, time, value)
  text = String.format("{0}{1}", tooltipHeader, if ranked && time then tooltipBody else "")

  wesCountry.charts.showTooltip(text, info.event)

getValue = (value, republish) ->
  if !republish then return "N/A"

  isNumeric = !isNaN(parseFloat(value)) && isFinite(value)

  if isNumeric then parseFloat(value).toFixed(2) else value
