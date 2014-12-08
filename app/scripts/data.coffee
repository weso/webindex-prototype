global = this
global.options = {}
global.selectorDataReady = {}
global.selections = {
  indicator: null,
  indicatorOption: null,
  indicatorTendency: null,
  countries: null,
  year: null,
  years: [],
  areas: []
}
global.maxChartBars = 5
global.continents = {}
global.tutorial = true
global.tutorialRestoreValues = {
  indicator: null,
  year: null,
  countries: null,
  selections: [false, false, false, false, false]
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
      startTutorialFirstTime()
    urlChanged: (parameters, selectors) ->
      url = wesCountry.stateful.getFullURL()

      if settings.debug then console.log url

    elements: [
      {
        name: "indicator",
        selector: "#indicator-select",
        onChange: (index, value, parameters, selectors) ->
          if settings.debug then console.log "indicator:onChange index:#{index} value:#{value}"

          option = selectors["#indicator-select"]?.options?[index]
          tendency = option.getAttribute("data-tendency")
          tendency = tendency == "1"

          global.selections.indicator = value
          global.selections.indicatorOption = option
          global.selections.indicatorTendency = tendency

          updateInfo()

          renderIndicatorInfo(option, tendency)

          if global.tutorial
            tutorialBoxOnChange.call(selectors["#indicator-select"])
            global.tutorialRestoreValues.selections[0] = true
      },
      {
        name: "time",
        selector: global.options.timeline,
        onChange: (index, value, parameters, selectors) ->
          if settings.debug then console.log "year:onChange index:#{index} value:#{value}"

          global.selections.year = parseInt(value)
          updateInfo()

          if global.tutorial
            tutorialBoxOnChange.call(global.options.timeline)
            global.tutorialRestoreValues.selections[1] = true
      },
      {
        name: "country",
        selector: global.options.countrySelector,
        value: "ALL",
        onChange: (index, value, parameters, selectors) ->
          if settings.debug then console.log "country:onChange index:#{index} value:#{value}"

          global.selections.countries = value
          updateInfo()

          text = "&nbsp;"
          if global.options.countrySelector.selectedLength() == global.maxChartBars
            text = document.getElementById("data_countries_reach").value || "&nbsp;"

          document.getElementById("third-box-help")?.innerHTML = text

          # Prevent select more countries that the limit by changing URL
          if global.options.countrySelector.selectedLength() > global.maxChartBars
            items = global.options.countrySelector.selected().split(",")
            if items.length > 0
              global.options.countrySelector.unselect(items[items.length - 1])
              global.options.countrySelector.refresh()

          if global.tutorial
            tutorialBoxOnChange.call(global.options.countrySelector)
            global.tutorialRestoreValues.selections[2] = true
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

  selector = document.getElementById("indicator-select")

  table = document.getElementById("indicator-list") || document.createElement "table"
  setIndicatorOptions(selector, table, indicators, 0, false)

  global.selectorDataReady.indicatorSelector = true
  checkSelectorDataReady()

  global.options.indicatorSelector = selector

setIndicatorOptions = (select, table, element, level, last) ->
  republish = if element.republish then element.republish else false
  type = if element.type then element.type else "Primary"
  description = if element.description then element.description else ""
  tendency = if element.high_low then element.high_low else "high"
  tendency = if tendency == "high" then 1 else -1
  provider_name = if element.provider_name then element.provider_name else ""
  provider_url = if element.provider_url then element.provider_url else ""
  weight = if element.weight then element.weight else ""
  subindex = if element.subindex then element.subindex else null
  if !subindex then subindex = element.indicator
  component = if element.component then element.component  else null
  if !component then component = element.indicator
  indicator = if element.indicator then element.indicator.replace(/_/g, " ")  else ""
  code = if element.indicator then element.indicator  else ""
  name = if element.name then element.name  else ""

  option = document.createElement("option")
  option.value = code
  option.setAttribute("data-republish", republish)
  option.setAttribute("data-type", type)
  option.setAttribute("data-name", name)
  option.setAttribute("data-subindex", subindex)
  option.setAttribute("data-component", component)
  option.setAttribute("data-description", description)
  option.setAttribute("data-tendency", tendency)
  option.setAttribute("data-provider_name", provider_name)
  option.setAttribute("data-provider_url", provider_url)

  space = Array(level * 3).join '&nbsp'
  option.innerHTML = space + name
  select.appendChild(option)

  # Table cells
  tbody = document.createElement "tbody"
  tbody.code = code
  tbody.setAttribute("data-subindex", if type.toLowerCase() != "subindex" then subindex else element.indicator)
  tbody.setAttribute("data-type", type)
  table.appendChild tbody
  tbody.onclick = ->
    code = this.code
    global.options.indicatorSelector.value = code
    global.options.indicatorSelector.refresh()

  if level == 3 && last
    tbody.className = "last"

  tr = document.createElement "tr"
  tbody.appendChild tr

  createTableCell(tr, "Indicator", name)
  createTableCell(tr, "Code", code)
  createTableCell(tr, "Type", type)
  createTableCell(tr, "Weight", weight)
  createTableCell(tr, "Provider", "<a href='#{provider_url}'>#{provider_name}</a>")
  createTableCell(tr, "Publish", if republish then "Yes" else "No")

  if description && description != ""
    tr = document.createElement "tr"
    tbody.appendChild tr
    createTableCell(tr, "Description", description, 6)

  # Loop children
  count = 0
  max = element.children.length - 1

  for child in element.children
    setIndicatorOptions(select, table, child, level + 1, count == max)
    count++

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

  for year, index in years
    years[index] = parseInt(years[index]) + 1

  global.selections.years = years

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
    maxSelectedItems: -1, # No limit, it's managed in beforeChange
    labelName: "short_name",
    valueName: "iso3",
    childrenName: "countries",
    autoClose: true,
    selectParentNodes: true,
    beforeChange: (selectedItems, element) ->
      if !global.options.countrySelector
        return

      isRegion = (element?.element?.data?.iso2 || null) == null

      if selectedItems.length == 0
        global.options.countrySelector.select("ALL")
        global.selections.areas = []
      else if element.code == "ALL"
        if selectedItems.length > 1
          global.options.countrySelector.clear()
          global.options.countrySelector.select("ALL")
          global.selections.areas = []
      else
        if selectedItems.search("ALL") != -1
          global.options.countrySelector.unselect("ALL")
        if isRegion
          # A region has been selected
          global.options.countrySelector.clear()
          global.options.countrySelector.select(element.code)
          global.selections.areas = [ element.code ]
        else
          # A country has been entered
          # Check if a region is entered, then clear
          if global.selections.areas.length > 0
            global.selections.areas = []
            global.options.countrySelector.clear()
            global.options.countrySelector.select(element.code)
          else
            # Check if country limit has been reached
            if global.options.countrySelector.selectedLength() == global.maxChartBars + 1
              global.options.countrySelector.unselect(element.code)

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

  countries = data.data.countries
  observationsByCountry = data.data.observationsByCountry
  renderCountries(countries, observationsByCountry)

  # region
  renderRegionLabel(data.data.region)

renderRegionLabel = (region) ->
  regionName = global.continents[region]
  document.getElementById("region-label")?.innerHTML = if region != "ALL" then " for <strong>#{regionName}</strong>" else ""

# Update information

updateInfo = () ->
  year = global.selections.year
  countries = global.selections.countries
  indicator = global.selections.indicator
  indicatorOption = global.selections.indicatorOption
  primary = true

  if settings.debug then console.log "year: #{year} countries: #{countries} indicator: #{indicator}"

  if !year or !countries or !indicator then return

  getObservations(indicator, countries, year - 1)

  if indicatorOption
    name = indicatorOption.getAttribute("data-name")
    document.getElementById("indicator")?.innerHTML = name
    document.getElementById("global-indicator")?.innerHTML = name
    type = indicatorOption.getAttribute("data-type")
    primary = type.toLowerCase() == "primary"

  yearContainer = document.getElementById("year")
  renderYearBox(yearContainer, primary, year)

  yearGlobalContainer = document.getElementById("global-year")
  renderYearBox(yearGlobalContainer, primary, year)

renderYearBox = (yearContainer, primary, year) ->
  yearContainer?.innerHTML = ""

  i = document.createElement "i"
  i.className = "fa fa-caret-left left"
  yearContainer?.appendChild i
  if !primary and global.selections.years.length > 0 and year > global.selections.years[0]
    i.className += " active"
    i.year = year - 1
    i.onclick = (event) ->
      global.options.timeline.select(this.year)
      global.options.timeline.refresh()

  span = document.createElement "span"
  span.innerHTML = year
  yearContainer?.appendChild span

  i = document.createElement "i"
  i.className = "fa fa-caret-right right"
  yearContainer?.appendChild i
  if global.selections.years.length > 0 and year < global.selections.years[global.selections.years.length - 1]
    i.className += " active"
    i.year = year + 1
    i.onclick = (event) ->
      global.options.timeline.select(this.year)
      global.options.timeline.refresh()

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
      rankingDirection: if global.selections.indicatorTendency then "HigherToLower" else "LowerToHigher",
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

    series = data.observations

    serieColours = wesCountry.makeGradientPalette(["#005475",
                                                  "#1B4E5A",
                                                  "#1B7A65",
                                                  "#83C04C",
                                                  "#E5E066"
                                                  ], data.bars.length)

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
      series: series,
      mean: {
        show: true
      },
      median: {
        show: true
      },
      width: view.offsetWidth,
      height: view.offsetHeight,
      serieColours: serieColours,
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

    if series.length > 10
      options.valueOnItem.rotation = -20

    wesCountry.charts.chart options

    # Line chart
    document.querySelector(lineContainer)?.innerHTML = ""

    values = if data.years then data.years else []

    for value, index in values
      values[index] = parseInt(values[index]) + 1

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
        values: values
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

  series = data.bars

  serieColours = wesCountry.makeGradientPalette(["#005475",
                                                "#1B4E5A",
                                                "#1B7A65",
                                                "#83C04C",
                                                "#E5E066"
                                                ], data.bars.length)

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
    series: series,
    mean: {
      show: true
    },
    median: {
      show: true
    },
    serieColours: serieColours,
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

  colours = ["#E5E066", "#83C04C", "#1B7A65", "#1B4E5A", "#005475"]
  if !global.selections.indicatorTendency then colours.reverse()

  map = wesCountry.maps.createMap({
    container: mapContainer,
    borderWidth: 1.5,
    landColour: "#dcdcdc",
    borderColour: "#fff",
    backgroundColour: "none",
    countries: global.observations,
    #width: view.offsetWidth,
    #height: view.offsetHeight,
    colourRange: colours,
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
  observations = if data.fullObservations then data.fullObservations else data.observations

  table = document.querySelector("#ranking")
  path = document.getElementById("path")?.value

  tbodies = document.querySelectorAll("#ranking > tbody")
  for tbody in tbodies
    table.removeChild tbody

  for observation in observations
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

    renderExtraTableHeader(extraTable)

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

renderExtraTableHeader = (extraTable) ->
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

renderIndicatorInfo = (option, tendency) ->
  # Show republish notification

  republish = option.getAttribute("data-republish")
  republish = republish == "true"

  document.getElementById("notifications")?.style?.display = if republish then "none" else "block"

  # Primary indicators don't have historical values
  type = option.getAttribute("data-type")
  index = type.toLowerCase() == "index"
  subindex = type.toLowerCase() == "subindex"
  component = type.toLowerCase() == "component"
  primary = type.toLowerCase() == "primary"
  secondary = type.toLowerCase() == "secondary"

  document.getElementById("primary-info")?.style?.display = if primary then "block" else "none"

  years = global.options.timeline.getElements()

  for i in [0..years.length - 2]
    year = years[i]

    if primary
      global.options.timeline.disable(year)
    else
      global.options.timeline.enable(year)

  # Name
  name = option.getAttribute("data-name")
  document.getElementById("indicator-name")?.innerHTML = name
  # Description
  description = option.getAttribute("data-description")
  document.getElementById("indicator-description")?.innerHTML = description
  # Type
  document.getElementById("indicator-type")?.innerHTML = type
  document.getElementById("indicator-type-icon")?.innerHTML = type
  # Tendency
  tendencyLabel = if tendency then document.getElementById("label_ascending")?.value else document.getElementById("label_descending")?.value
  document.getElementById("indicator-tendency")?.innerHTML = tendencyLabel
  document.getElementById("indicator-tendency-icon")?.innerHTML = tendencyLabel
  tendencyIcon = if tendency then "fa fa-arrow-up" else "fa fa-arrow-down"
  document.getElementById("indicator-tendency-arrow")?.className = tendencyIcon
  # Provider
  provider_name = option.getAttribute("data-provider_name")
  provider_url = option.getAttribute("data-provider_url")
  provider_anchor = "<a href='#{provider_url}'>#{provider_name}</a>"
  document.getElementById("indicator-provider")?.innerHTML = provider_anchor
  document.getElementById("indicator-provider-icon")?.innerHTML = provider_anchor

  # Hierarchy
  hierarchy = document.getElementById("hierarchy")

  indexBox = hierarchy.querySelector(".index")
  subindexBox = hierarchy.querySelector(".subindex")
  componentBox = hierarchy.querySelector(".component")
  indicatorBox = hierarchy.querySelector(".indicator")

  subindexNameSpan = hierarchy.querySelector(".subindex .name")
  componentNameSpan = hierarchy.querySelector(".component .name")
  indicatorNameSpan = hierarchy.querySelector(".indicator .name")

  subindexName = option.getAttribute("data-subindex")
  componentName = option.getAttribute("data-component")
  indicatorName = name
  indicatorValue = option.value

  subindexNameSpan?.innerHTML = subindexName.replace(/_/g, " ").toLowerCase()
  componentNameSpan?.innerHTML = componentName.replace(/_/g, " ").toLowerCase()
  indicatorNameSpan?.innerHTML = indicatorName

  subindexBox.setAttribute("data-subindex", subindexName)
  componentBox.setAttribute("data-subindex", subindexName)
  indicatorBox.setAttribute("data-subindex", subindexName)

  if primary or secondary
    show(indicatorBox)
    show(componentBox)
    show(subindexBox)
  else if component
    hide(indicatorBox)
    show(componentBox)
    show(subindexBox)
  else if subindex
    hide(indicatorBox)
    hide(componentBox)
    show(subindexBox)
  else if index
    hide(indicatorBox)
    hide(componentBox)
    hide(subindexBox)

  indicatorBox.onclick = ->
    global.options.indicatorSelector.value = indicatorValue
    global.options.indicatorSelector.refresh()
  componentBox.onclick = ->
    global.options.indicatorSelector.value = componentName
    global.options.indicatorSelector.refresh()
  subindexBox.onclick = ->
    global.options.indicatorSelector.value = subindexName
    global.options.indicatorSelector.refresh()
  indexBox.onclick = ->
    global.options.indicatorSelector.value = "INDEX"
    global.options.indicatorSelector.refresh()

show = (element) ->
  element.style.display = "block"

hide = (element) ->
  element.style.display = "none"

renderBoxes = (data) ->
  # Global boxes
  renderSomeBoxes(data.statistics, "")
  # Country boxes
  renderSomeBoxes(data.globalStatistics, "global-")

renderSomeBoxes = (data, prefix) ->
  mean = data.mean
  median = data.median
  higher = data.higher["short_name"]
  lower = data.lower["short_name"]

  higherArea = data.higher.area
  lowerArea = data.lower.area

  document.getElementById("#{prefix}mean")?.innerHTML = mean.toFixed(2);
  document.getElementById("#{prefix}median")?.innerHTML = median.toFixed(2);

  higherContainer = document.getElementById("#{prefix}higher")
  if higherContainer
    higherContainer.innerHTML = if global.selections.indicatorTendency then higher else lower

    higherContainer.onclick = ->
      global.options.countrySelector.select(higherArea)
      global.options.countrySelector.refresh()

  lowerContainer = document.getElementById("#{prefix}lower")
  if lowerContainer
    lowerContainer.innerHTML = if global.selections.indicatorTendency then lower else higher

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

selectBar = $(".select-bar > section")
siteHeader = null

if !selectBar then return;

firstBox = document.querySelector(".first-box")
secondBox = document.querySelector(".second-box")
thirdBox = document.querySelector(".third-box")

firstHeight = null
secondHeight = null
thirdHeight = null
thirdHeight = null

firstBoxHeaderHeight = null
secondBoxHeaderHeight = null
thirdBoxHeaderHeight = null

totalHeight = null

top = null

if !msie6
  $(window).scroll((event) ->
    top ?= selectBar.offset().top
    siteHeader ?= $(".site-header").height()

    firstHeight = if firstBox then firstBox.offsetHeight else 0
    secondHeight = if secondBox then secondBox.offsetHeight else 0
    thirdHeight = if thirdBox then thirdBox.offsetHeight else 0

    firstBoxHeaderHeight = firstBox?.querySelector("header")?.offsetHeight || 0
    secondBoxHeaderHeight = secondBox?.querySelector("header")?.offsetHeight || 0
    thirdBoxHeaderHeight = thirdBox?.querySelector("header")?.offsetHeight || 0

    thirdHeight = (thirdHeight - thirdBoxHeaderHeight) * 2.8 # Height when open

    totalHeight = firstHeight + secondHeight + thirdHeight - firstBoxHeaderHeight - secondBoxHeaderHeight

    # What the y position of the scroll is
    y = $(this).scrollTop()

    # Whether that's below the form
    if !global.tutorial and y >= siteHeader and totalHeight < window.innerHeight
      if !selectBar.collapsed
        setBoxesInitialPosition()
        # if so, add the class
        selectBar.addClass("fixed")
        setBoxesPosition()
        selectBar.collapsed = true
        selectBar.css("width", selectBar.parent().width())
    else
      # otherwise remove it
      setUnfixedPosition()
  )

setUnfixedPosition = ->
  selectBar.removeClass("fixed")
  selectBar.collapsed = false

  boxes = document.querySelectorAll(".select-box")

  for box in boxes
    box.style.top = "0px"

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

collapsables = document.querySelectorAll(".collapsable-header")

for collapsableHeader in collapsables
  button = collapsableHeader.querySelector(".button")
  if !button then continue

  collapsable = collapsableHeader.parentNode

  collapsableSection = collapsable.querySelector("section")

  if ! collapsableSection then continue

  collapsed = collapsable.className.indexOf("collapsed") != -1

  button.collapsed = collapsed
  button.container = collapsable

  button.setStyles = ->
    collapsed = this.collapsed
    container = this.container
    containerClass = container.className.replace(" collapsed", "")
    container.className = if collapsed then containerClass + " collapsed"  else containerClass
    this.className = if collapsed then "button fa fa-toggle-off" else "button fa fa-toggle-on"

  button.onclick = ->
    this.collapsed = !this.collapsed
    this.setStyles()

  button.setStyles()

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
  time = parseInt(info["data-year"]) + 1

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

################################################################################
#                               ACCORDION TABS
################################################################################

tabs = document.querySelectorAll(".accordion-tabs-minimal li")

if tabs.length > 0
  a = tabs[0].querySelector("a")
  content = tabs[0].querySelector("div.tab-content")
  a.className += " is-active"
  content.className += " is-open"

for tab in tabs
  a = tab.querySelector("a")
  a?.onclick = (event) ->
    if this.className.indexOf("is-active") == -1
      event.preventDefault()
      open = document.querySelector(".accordion-tabs-minimal .is-active")
      open?.className = open.className.replace(" is-active", "")
      open = document.querySelector(".accordion-tabs-minimal .is-open")
      open?.className = open.className.replace(" is-open", "")

      this.className += " is-active"
      content = this.parentNode.querySelector("div.tab-content")
      content?.className += " is-open"
    else
      event.preventDefault()

################################################################################
#                               RENDER COUNTRIES
################################################################################

renderCountries = (countries, observations) ->
  container = document.getElementById("country-section")

  container?.style.display = if global.selections.countries == "ALL" then "none" else "block"

  selectedCountries = global.selections.countries
  selectedCountries = selectedCountries.split(",")

  ul = document.getElementById("country-tabs")
  ul.innerHTML = ""

  count = 1

  for country in selectedCountries
    country = countries[country]

    if !country then continue

    renderCountryInfo = (country, count) ->
      code = country.iso3
      name = country.name
      continent = country.area
      observation = observations[code]
      republish = if observation.republish then observation.republish else false
      value = if observation.values && observation.values.length > 0 then observation.values[0] else observation.value
      value = getValue(value, republish)
      ranking = observation.ranked
      extraInfo = observation.extra
      globalRank = extraInfo.rank
      universalAccess = extraInfo["UNIVERSAL_ACCESS"].toFixed(2)
      freedomOpenness = extraInfo["FREEDOM_AND_OPENNESS"].toFixed(2)
      relevantContent = extraInfo["RELEVANT_CONTENT_AND_USE"].toFixed(2)
      empowerment = extraInfo["EMPOWERMENT"].toFixed(2)

      if continent
        continent = global.continents[continent]
      else
        continent = ""

      li = document.createElement "li"
      li.className = "tab-header-and-content"
      ul.appendChild li

      a = document.createElement "a"
      a.href = "javascript:void(0)"
      a.className = if count == 1 then "tab-link is-active" else "tab-link"
      a.opened = false
      li.appendChild a

      img = document.createElement "img"
      img.className = "flag"
      path = document.getElementById("path").value
      img.src = "#{path}/images/flags/#{code}.png"
      a.appendChild img

      span = document.createElement "span"
      span.className = "country"
      a.appendChild span
      span.innerHTML = country.short_name

      div = document.createElement "div"
      div.className = if count == 1 then "tab-content is-open" else "tab-content"
      li.appendChild div
      a.container = div

      a.onclick = (event) ->
        if this.className.indexOf("is-active") == -1
          event.preventDefault()
          open = document.querySelector(".accordion-tabs-minimal .is-active")
          open?.className = open.className.replace(" is-active", "")
          open = document.querySelector(".accordion-tabs-minimal .is-open")
          open?.className = open.className.replace(" is-open", "")

          this.className += " is-active"
          content = this.parentNode.querySelector("div.tab-content")
          content?.className += " is-open"
        else
          event.preventDefault()

        if this.opened then return

        this.opened = true
        div = this.container

        map = document.createElement "div"
        map.className = "country-map"
        map.id = "m" + wesCountry.guid()
        div.appendChild map

        countryMap = wesCountry.maps.createMap({
          container: "##{map.id}",
          "borderWidth": 1.5,
          countries: [{
            code: code,
            value: 1
          }],
          download: false,
          "zoom": false,
          landColour: "#ddd",
          borderColour: "#ddd",
          colourRange: ["#0096af"]
        })

        wrapper = document.createElement "div"
        div.appendChild wrapper

        valueDiv = document.createElement "div"
        valueDiv.className = "value"
        valueDiv.innerHTML = "<p>value</p>#{value}"
        wrapper.appendChild valueDiv

        rankingDiv = document.createElement "div"
        rankingDiv.className = "value ranking"
        rankingDiv.innerHTML = "<p>rank</p>#{ranking}"
        wrapper.appendChild rankingDiv

        p = document.createElement "p"
        wrapper.appendChild p

        p.innerHTML = name

        p = document.createElement "p"
        p.className = "continent"
        wrapper.appendChild p

        p.innerHTML = continent

        tableWrapper = document.createElement "div"
        tableWrapper.className = "table-wrapper"
        div.appendChild tableWrapper

        table = document.createElement "table"
        table.className = "extra-table"
        tableWrapper.appendChild table

        # thead
        renderExtraTableHeader(table)

        # tbody
        extraTbody = document.createElement "tbody"
        table.appendChild extraTbody

        tr = document.createElement "tr"
        extraTbody.appendChild tr

        td = document.createElement "td"
        td.setAttribute("data-title", "Web Index Rank")
        tr.appendChild td

        td.innerHTML = globalRank

        td = document.createElement "td"
        td.setAttribute("data-title", "Universal Access")
        tr.appendChild td

        renderPieChart(td, universalAccess, "#f93845")

        td = document.createElement "td"
        td.setAttribute("data-title", "Relevant Content")
        tr.appendChild td

        renderPieChart(td, freedomOpenness, "#0096af")

        td = document.createElement "td"
        td.setAttribute("data-title", "Freedom And Openness")
        tr.appendChild td

        renderPieChart(td, relevantContent, "#89ba00")

        td = document.createElement "td"
        td.setAttribute("data-title", "Empowerment")
        tr.appendChild td

        renderPieChart(td, empowerment, "#ff761c")

      if count == 1
        a.click()

    renderCountryInfo(country, count)
    count++

renderPieChart = (container, value, colour) ->
  chart = document.createElement "div"
  chart.className = "chart"
  chart.id = "c#{wesCountry.guid()}"
  container.appendChild chart

  pie = wesCountry.charts.chart({
    chartType: "pie",
    container: "##{chart.id}",
    serieColours: ["#ddd", colour]
    series: [
      {
        name: "",
        values: [100 - value]
      },
      {
        name: name,
        values: [value]
      }
    ],
    events: {
      onmouseover: ->
    },
    valueOnItem: {
      show: false
    },
    xAxis: {
      "font-colour": "none"
    },
    yAxis: {
      "font-colour": "none"
    },
    legend: {
      show: false
    },
    margins: [0, 0, 0, 0]
  })

################################################################################
#                                  TABLE CELL
################################################################################

createTableCell = (tr, title, content, colspan) ->
  td = document.createElement "td"
  td.setAttribute("data-title", title)
  td.innerHTML = content
  tr.appendChild td

  if colspan
    td.setAttribute("colspan", colspan)

################################################################################
#                               MOVING TABS
################################################################################
###
msie6 = $.browser is "msie" and $.browser.version < 7

siteHeader = $(".site-header").height()
firstSection = $(".first-section")
firstTab = $(".first-tab")
secondTab = $(".second-tab")
firstTabFixedPosition = 0
secondTabAbsolutePosition = 0
firstTabStartedMoving = 0
secondTabStartedMoving = 0
selectBar = $(".select-bar > section")

if !selectBar then return;

top = null
previousY = 0

if !msie6
  $(window).scroll((event) ->
    top ?= section.offset().top

    windowHeight = $(window).height()
    fistTabHeight = firstTab.height()

    # What the y position of the scroll is
    y = $(this).scrollTop()
    tendency = y - previousY

    firstTabTop = Math.floor(y - firstTab.offset().top)
    secondTabTop = Math.floor(y - secondTab.offset().top)

    # Whether that's below the form
    if !global.tutorial and y >= siteHeader and windowHeight > fistTabHeight
      if !firstSection.collapsed and tendency > 0
        parent = firstSection.parent()
        height = parent.height()

        parent.css("min-height", height)

        firstSection.siblings().each(->
            offset = $(this).position().top
            secondTabAbsolutePosition = offset
            $(this).css("top", offset)
            $(this).addClass("absolute")
        )

        firstTabFixedPosition = firstTab.position().top
        firstSection.children().each(->
          width = $(this).width()
          $(this).css("width", width)
          $(this).addClass("fixed")
        )
        firstTab.css("top", firstTabFixedPosition)
        firstSection.collapsed = true
        secondTabStartedMoving = y
      else if !firstTab.moving && tendency > 0 && secondTabTop >= firstTabTop
        offset = secondTabAbsolutePosition - 6
        firstTab.css("top", offset).addClass("absolute").removeClass("fixed")
        firstTab.moving = true
        firstTabStartedMoving = y
      else if tendency < 0 && firstTab.moving && y <= firstTabStartedMoving
        firstTab.css("top", firstTabFixedPosition).addClass("fixed").removeClass("absolute")
        firstTab.moving = false
      else if tendency < 0 && y <= secondTabStartedMoving
        returnToStoppedPosition(firstSection, firstTab)
    else
      returnToStoppedPosition(firstSection, firstTab)

    previousY = y
  )

returnToStoppedPosition = (firstSection, firstTab) ->
  if !firstSection.collapsed then return

  firstSection.children().removeClass("fixed").removeClass("absolute")
  firstSection.collapsed = false
  firstTab.moving = false

  firstSection.siblings().each(->
      $(this).removeClass("absolute")
  )
###
################################################################################
#                                  TUTORIAL
################################################################################

startTutorialFirstTime = ->
  if typeof(Storage) != "undefined"
    shown = localStorage.getItem("tutorialShown")

    if !shown
      showTutorial()
    else
      global.tutorial = false
  else
    global.tutorial = false

showTutorial = ->
  global.tutorial = true
  window.scrollTo(0, 0)

  # Save restore selector values
  global.tutorialRestoreValues = {
    indicator: document.getElementById("indicator-select").value,
    year: global.options.timeline.selected(),
    countries: global.options.countrySelector.selected(),
    selections: [false, false, false, false, false]
  }
  # Set initial values for selectors
  global.options.indicatorSelector.value = -1
  global.options.timeline.clear()
  global.options.countrySelector.clear()

  # Uncollapse left bar
  setUnfixedPosition()

  localStorage.setItem("tutorialShown", true)
  tutorial = document.querySelector(".tutorial")
  document.body.appendChild tutorial

  back = document.createElement "div"
  back.className = "tutorial-back"
  document.body.appendChild back

  tutorialElements = [
    ".first-box",
    ".second-box",
    ".third-box",
    ".first-tab",
    ".second-tab"
  ]

  tutorial.style.display = "block"

  createTip(tutorial, tutorialElements, 0, back)

# Box on change

tutorialBoxOnChange = () ->
  if (this.selectedIndex and this.selectedIndex != -1) or (this.selected and this.selected() != -1 and this.selected != "")
    document.getElementById("tutorial-next").setAttribute("status", "active")
    document.getElementById("tutorial-next")?.click()

# Restore selectors if tutorial closed
tutorialRestore = () ->
  if global.options.indicatorSelector.selectedIndex == -1
    global.options.indicatorSelector.value = global.tutorialRestoreValues.indicator
    global.options.indicatorSelector.refresh()
  if global.options.timeline.selected() == -1
    global.options.timeline.select(global.tutorialRestoreValues.year)
    global.options.timeline.refresh()
  if global.options.countrySelector.selected() == ""
    global.options.countrySelector.select(global.tutorialRestoreValues.countries)
    global.options.countrySelector.refresh()

# Show tutorial on demand

document.getElementById("view-tutorial")?.onclick = (event) ->
  showTutorial()

# Auxiliary tutorial functions

createTip = (tutorial, elements, index, back) ->
  element = elements[index]
  number = index + 1
  total = elements.length

  elementBox = $(element)
  elementBox.addClass("tutorial-element")

  step = document.getElementById("tutorial-step")
  step.innerHTML = ""

  span = document.createElement "span"
  span.className = "number large-text"
  span.innerHTML = "#{number}/#{total}"
  step.appendChild span

  text = document.getElementById("data_tutorial_step_#{number}")?.value || ""
  textNode = document.createTextNode text
  step.appendChild textNode

  # Enjoy
  document.getElementById("tutorial-enjoy")?.style?.display = if index < total - 1 then "none" else "block"

  # Close
  closes = document.querySelectorAll(".tutorial-close")

  for close in closes
    close.onclick = (event) ->
      removePreviousStep()
      global.tutorial = false
      back.parentNode?.removeChild? back
      tutorial.style.display = "none"
      tutorialRestore()

  # Arrow
  arrowContainer = document.createElement "div"
  arrowContainer.style.position = "absolute"
  tutorial.appendChild arrowContainer

  arrow = document.createElement "i"
  if index < total - 1
    arrow.className = "fa fa-long-arrow-left fa-5x bouncing-arrow-left"
    arrowContainer.style.left = elementBox.offset().left + elementBox.width() + 5 + "px"
  else
    arrow.className = "fa fa-long-arrow-down fa-5x bouncing-arrow-down"
    arrowContainer.style.left = elementBox.offset().left + elementBox.width() / 2 + "px"
  arrowContainer.appendChild arrow

  if index < total - 1
    arrowContainer.style.top = elementBox.offset().top + elementBox.height() / 2 - arrow.offsetHeight / 2 + "px"
  else
    arrowContainer.style.top = elementBox.offset().top - arrow.offsetHeight / 2 - 25 + "px"

  # Previous and next buttons
  previous = document.getElementById("tutorial-previous")
  next = document.getElementById("tutorial-next")

  previousStatus = if index > 0 then "active" else "inactive"

  nextStatus = "inactive"
  if index >= 3 and index < total - 1
    nextStatus = "active"
  else if index < 3 and global.tutorialRestoreValues.selections[index]
    nextStatus = "active"

  previous.setAttribute("status", previousStatus)
  next.setAttribute("status", nextStatus)

  removePreviousStep = ->
    elementBox.removeClass("tutorial-element")
    arrow.parentNode.removeChild arrow

  if index > 0
    previous.onclick = (event) ->
      removePreviousStep()
      createTip(tutorial, elements, index - 1, back)
  else
    previous.onclick = (event) ->

  if index < total - 1
    next.onclick = (event) ->
      status = this.getAttribute("status")
      if status == "inactive" then return
      removePreviousStep()
      createTip(tutorial, elements, index + 1, back)
  else
    next.onclick = (event) ->
