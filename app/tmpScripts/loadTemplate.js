function loadTemplate(name, templateData) {
  var source;
  var template;
  var path = 'views/' + name + '.hbs'

  loadLabels("en", function(labels) {
    templateData.labels = labels;

    $.ajax({
        url: path,
        cache: true,
        success: function (data) {
          source = "{{>header}}" + data + "{{>footer}}";
          template = Handlebars.compile(source);

          $('#content').html(template(templateData));
        }
    });
  });
};

function loadLabels(language, callback) {
  var source;
  var template;
  var path = 'lang/' + language + '.json'

  $.ajax({
      url: path,
      cache: true,
      success: function (data) {
        callback(data)
      }
  });
};

function loadPartial(name, callback) {
  var path = 'views/partials/' + name + '.hbs'

  $.ajax({
      url: path,
      cache: true,
      success: function (data) {
        Handlebars.registerPartial(name, data);

        callback();
      },
  });
};

function loadPartials(partials, callback) {
  var count = partials.length;

  for (var i = 0; i < partials.length; i++) {
    var partial = partials[i];

    loadPartial(partial, function() {
      count--;

      if (count <= 0)
        callback();
    });
  }
}
