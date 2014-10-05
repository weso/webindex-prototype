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
      url: "http://localhost:5000"
    }
  },
  mode: if @mode then @mode else "release"
}

@settings = settings[settings.mode]
