global = this
global.options = {}
global.selectorDataReady = {}
global.selections = {
  indicator: null,
  countries: null,
  year: null
}
global.maxTableRows = 7

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
    processJSONP(url)
  else
    processAJAX(url, getYearsCallback)

@getIndicatorsCallback = (data) ->
  indicators = []

  if data.success then indicators = data.data

  setIndicatorOptions(document.getElementById("indicator-select"), indicators, 0)

  global.selectorDataReady.indicatorSelector = true
  checkSelectorDataReady()

setIndicatorOptions = (select, element, level) ->
  option = document.createElement("option")
  option.value = element.indicator
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
    processJSONP(url)
  else
    processAJAX(url, getYearsCallback)

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
    processJSONP(url)
  else
    processAJAX(url, getYearsCallback)

@getCountriesCallback = (data) ->
  countries = []

  if data.success then countries = data.data

  countries.unshift({
    name: "All countries",
    iso3: "ALL"
  })

  # Country selector

  global.options.countrySelector = new wesCountry.selector.basic({
    data: countries,
    selectedItems: ["ALL"],
    maxSelectedItems: global.maxTableRows,
    labelName: "name",
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
    processJSONP(url)
  else
    processAJAX(url, getObservationsCallback)

@getObservationsCallback = (data) ->
  if !data.success then return

  observations = data.data
  renderCharts(observations)
  renderTable(observations)
  renderBoxes(observations)

# Auxiliary communication functions

processJSONP = (url) ->
  head = document.head
  script = document.createElement("script")

  script.setAttribute("src", url)
  head.appendChild(script)
  head.removeChild(script)

processAJAX = (url, callback) ->

# Update information

updateInfo = () ->
  year = global.selections.year
  countries = global.selections.countries
  indicator = global.selections.indicator

  if settings.debug then console.log "year: #{year} countries: #{countries} indicator: #{indicator}"

  if !year or !countries or !indicator then return

  getObservations(indicator, countries, year)

renderCharts = (data) ->
  mapContainer = "#map"
  barContainer = "#country-bars"
  lineContainer = "#lines"
  rankingContainer = "#ranking"

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

    document.querySelector(rankingContainer)?.innerHTML = ""

    options = {
      maxRankingRows: 10,
      margins: [4, 12, 1, 0],
      container: rankingContainer,
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
        "font-family": "'Kite One', sans-serif",
        "font-size": "14px"
      },
      serieColours: ["#0489B1", "#088A68", "#21610B", "#DBA901", "#084B8A"],
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
      getElementColour: (options, element, index) ->
        pos = 0

        switch element.continent
          when "ECS"
            pos = 0
          when "NAC"
            pos = 1
          when "LCN"
            pos = 1
          when "AFR"
            pos = 2
          when "SAS"
            pos = 3
          when "EAS"
            pos = 3
          when "MEA"
            pos = 4

        return options.serieColours[pos]
      getLegendElements: (options) ->
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
      events: {
        onclick: (info) ->
          code = info["data-code"]
          global.options.countrySelector.select(code)
          global.options.countrySelector.refresh()
      }
    }

    wesCountry.charts.chart options
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
        rank = if element.rank then element.rank - 1 else index
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
      }
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
      },
      getName: (serie) ->
        serie.area_name
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
    margins: [8, 1, 0, 2.5],
    yAxis: {
      margin: 2,
      title: ""
    },
    valueOnItem: {
      show: false
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
    }
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
  mapContainer = "#map"
  document.querySelector(mapContainer)?.innerHTML = ""

  map = wesCountry.maps.createMap({
    container: mapContainer,
    borderWidth: 1.5,
    landColour: "#E4E5D8",
    borderColour: "#E4E5D8",
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
  })

renderTable = (data) ->
  observations = data.observations
  byCountry = data.byCountry
  years = data.years

  table = document.querySelector("#data-table tbody")
  path = document.getElementById("path")?.value

  table.innerHTML = ""

  count = 0

  for observation in observations
    count++
    code = observation.code
    name = observation.area_name
    rank = if observation.rank then observation.rank else count
    value = if observation.values && observation.values.length > 0 then observation.values[0] else observation.value
    previousValue = observation.previous_value
    tendency = 0

    if previousValue
      tendency = previousValue.tendency

    tr = document.createElement "tr"
    table.appendChild tr

    if count > global.maxTableRows
      tr.className = "to-hide"

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
    td.setAttribute("data-title", "Rank")
    tr.appendChild td

    td.innerHTML = rank

    td = document.createElement "td"
    td.setAttribute("data-title", "Value")
    tr.appendChild td

    td.innerHTML = value

    i = document.createElement "i"
    className = "fa fa-minus"

    if tendency == 1
      className = "fa fa-long-arrow-up green"

    if tendency == -1
      className = "fa fa-long-arrow-down red"

    i.className = className
    td.appendChild i

    td = document.createElement "td"
    td.setAttribute("data-title", "Tendency")
    tr.appendChild td

    div = document.createElement "div"
    id = wesCountry.guid()
    div.id = "g#{id}"
    td.appendChild div

    renderTendencyChart("#g#{id}", byCountry[code], years)

  if count > global.maxTableRows
    rows = table.querySelectorAll(".to-hide")

    for row in rows
      row.className = "hidden"

    tr = document.createElement "tr"
    table.appendChild tr

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

      rows = this.table.querySelectorAll("tr.#{className}")

      for row in rows
        row.className = newClassName

renderTendencyChart = (container, serie, years) ->
  if !serie then return

  options = {
    container: container,
    chartType: "line",
    margins: [0, 0, 0, 0],
    groupMargin: 0,
    yAxis: {
      title: "",
      "font-colour": "transparent",
      tickColour: "none"
    },
    xAxis: {
      title: "",
      "font-colour": "transparent"
      values: years
    },
    series: [ serie ],
    valueOnItem: {
      show: false
    },
    vertex: {
      show: false
    },
    legend: {
      show: false
    },
    serieColours: ["#333"]
  }

  wesCountry.charts.chart options

renderBoxes = (data) ->
  mean = data.mean
  median = data.median
  higher = data.higher.area
  lower = data.lower.area

  document.getElementById("mean")?.innerHTML = mean.toFixed(2);
  document.getElementById("median")?.innerHTML = median.toFixed(2);
  document.getElementById("higher")?.innerHTML = higher
  document.getElementById("lower")?.innerHTML = lower

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
