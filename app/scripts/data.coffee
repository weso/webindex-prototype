global = this
global.options = {}
global.selectorDataReady = {}
global.selections = {
  indicator: null,
  countries: null,
  year: null
}

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
        name: "year",
        selector: global.options.timeline,
        onChange: (index, value, parameters, selectors) ->
          if settings.debug then console.log "year:onChange index:#{index} value:#{value}"

          global.selections.year = value
          updateInfo()
      },
      {
        name: "country",
        selector: global.options.countrySelector,
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
    onChange: null,
    selectedItems: ["ALL"],
    maxSelectedItems: 3,
    labelName: "name",
    valueName: "iso3",
    childrenName: "countries",
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

  if global.selections.countries == "ALL"
    # Show map
    document.querySelector(mapContainer)?.style.display = 'block';
    # Hide country bars
    document.querySelector(barContainer)?.style.display = 'none';

    # Map

    document.querySelector(mapContainer)?.innerHTML = ""

    map = wesCountry.maps.createMap({
      container: mapContainer,
      borderWidth: 1.5,
      landColour: "#E4E5D8",
      borderColour: "#E4E5D8",
      backgroundColour: "none",
      countries: data.observations,
      colourRange: ["#E5E066", "#83C04C", "#1B7A65", "#1B4E5A", "#005475"]
    })
  else
    # Show country bars
    document.querySelector(barContainer)?.style.display = 'block';
    # Hide map
    document.querySelector(mapContainer)?.style.display = 'none';

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
      series: data.observations,
      mean: {
        show: true
      },
      median: {
        show: true
      }
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
    }
  }

  length = data.bars.length

  colours = [
    {
      r: 0,
      g: 84,
      b: 117
    },
    {
      r: 27,
      g: 78,
      b: 90
    },
    {
      r: 27,
      g: 122,
      b: 101
    },
    {
      r: 131,
      g: 192,
      b: 76
    },
    {
      r: 229,
      g: 224,
      b: 102
    }
  ]

  options.serieColours = []

  index = 0
  colourLength = colours.length

  intervalLength = length / (colourLength - 1)
  range = [0..intervalLength]

  while (index < colourLength - 1)
    for i in range
      colour1 = colours[index]
      colour2 = colours[index + 1]
      options.serieColours.push(wesCountry.makeGradientColour(colour1, colour2, (i / intervalLength) * 100).cssColour)
    index++

  options.getElementColour = (options, element, index) ->
    return options.serieColours[index]

  wesCountry.charts.chart options

  # Window resize

  if window.attachEvent
    window.attachEvent("onresize", resize)
  else
    window.addEventListener("resize", resize, false)

  resize = ->
    createMap()

# Script load

setTimeout(->
            getSelectorData()
, @settings.elapseTimeout)
