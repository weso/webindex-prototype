settings = {
  debug: {
    debug: true,
    elapseTimeout: 100,
    server: {
      method: "JSONP",
      url: "http://localhost:5000"
    }
  },
  release: {
    debug: false,
    elapseTimeout: 0,
    server: {
      method: "JSONP",
      url: document.getElementById("api").value
    }
  },
  mode: if @mode then @mode else "release"
}

@settings = settings[settings.mode]

# Auxiliary communication functions

@processJSONP = (url) ->
  head = document.head
  script = document.createElement("script")

  script.setAttribute("src", url)
  head.appendChild(script)
  head.removeChild(script)

@processAJAX = (url, callback) ->
