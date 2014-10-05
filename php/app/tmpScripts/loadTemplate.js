function loadTemplate(name, data) {
  var source;
  var template;
  var path = 'views/' + name + '.hbs'

  $.ajax({
      url: path,
      cache: true,
      success: function (data) {
        source = data;
        template = Handlebars.compile(source);

        $('#content').html(template(data));
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