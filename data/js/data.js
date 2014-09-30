wesCountry.stateful.start({
  elements: [
    {
      name: "indicator",
      selector: "#indicator-select",
      onChange: function() {
        console.log(this);
      }
    }
  ]
});

wesCountry.stateful.start({
  elements: [
    {
      name: "area",
      selector: "#area-select",
      onChange: function() {
        console.log(this);
      }
    }
  ]
});

wesCountry.stateful.start({
  elements: [
    {
      name: "year",
      selector: "#year-select",
      onChange: function() {
        console.log(this);
      }
    }
  ]
});
