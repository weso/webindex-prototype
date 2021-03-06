(function() {
  var a, article, articles, left, p, paragraph, sibling, tag, tags, _i, _j, _len, _len1, _ref;

  articles = document.querySelectorAll(".about-articles article");

  for (_i = 0, _len = articles.length; _i < _len; _i++) {
    article = articles[_i];
    paragraph = article.querySelector("p:nth-of-type(5)");
    if (!paragraph) {
      continue;
    }
    sibling = paragraph.nextSibling;
    left = 0;
    while (sibling) {
      if (sibling && sibling.innerHTML) {
        left++;
      }
      sibling = sibling.nextSibling;
    }
    if (left < 4) {
      continue;
    }
    sibling = paragraph.nextSibling;
    while (sibling) {
      sibling.className = sibling.className === "" ? "element-hidden" : sibling.className + " element-hidden";
      sibling = sibling.nextSibling;
    }
    p = document.createElement("p");
    p.className = "text-right clear";
    if ((_ref = paragraph.parentNode) != null) {
      _ref.appendChild(p);
    }
    a = document.createElement("a");
    a.innerHTML = "READ MORE <span>&#187;</span>";
    a.className = "read-more";
    p.appendChild(a);
    a.container = paragraph.parentNode;
    a.collapsed = true;
    a.onclick = function(event) {
      var className, container, element, elements, newClassName, _j, _len1;
      container = this.container;
      className = this.collapsed ? "element-hidden" : "element-shown";
      newClassName = this.collapsed ? "element-shown" : "element-hidden";
      elements = container.querySelectorAll("." + className);
      for (_j = 0, _len1 = elements.length; _j < _len1; _j++) {
        element = elements[_j];
        element.className = element.className.replace(className, newClassName);
      }
      this.innerHTML = this.collapsed ? "<span>&#171;</span> READ LESS" : "READ MORE <span>&#187;</span>";
      return this.collapsed = !this.collapsed;
    };
    a.open = function() {
      if (this.collapsed) {
        return this.click();
      }
    };
    tags = article.querySelectorAll("ul.tags li a");
    for (_j = 0, _len1 = tags.length; _j < _len1; _j++) {
      tag = tags[_j];
      tag.readMore = a;
      tag.onclick = function(event) {
        this.readMore.open();
        return true;
      };
    }
  }

}).call(this);
