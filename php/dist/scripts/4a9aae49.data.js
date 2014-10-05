(function(){var a,b,c,d,e,f,g,h,i,j,k,l,m;g=this,g.options={},g.selectorDataReady={},g.selections={indicator:null,countries:null,year:null},l=function(){return wesCountry.stateful.start({init:function(){return settings.debug?console.log("init"):void 0},urlChanged:function(){var a;return a=wesCountry.stateful.getFullURL(),settings.debug?console.log(a):void 0},elements:[{name:"indicator",selector:"#indicator-select",onChange:function(a,b){return settings.debug&&console.log("indicator:onChange index:"+a+" value:"+b),g.selections.indicator=b,m()}},{name:"year",selector:g.options.timeline,onChange:function(a,b){return settings.debug&&console.log("year:onChange index:"+a+" value:"+b),g.selections.year=b,m()}},{name:"country",selector:g.options.countrySelector,onChange:function(a,b){return settings.debug&&console.log("country:onChange index:"+a+" value:"+b),g.selections.countries=b,m()}}]})},e=function(){return c(),f(),b()},c=function(){var a,b;return a=this.settings.server.url,b=""+a+"/indicators/INDEX","JSONP"===this.settings.server.method?(b+="?callback=getIndicatorsCallback",i(b)):h(b,getYearsCallback)},this.getIndicatorsCallback=function(b){var c;return c=[],b.success&&(c=b.data),k(document.getElementById("indicator-select"),c,0),g.selectorDataReady.indicatorSelector=!0,a()},k=function(a,b,c){var d,e,f,g,h,i,j;for(e=document.createElement("option"),e.value=b.indicator,f=Array(3*c).join("&nbsp"),e.innerHTML=f+b.name,a.appendChild(e),i=b.children,j=[],g=0,h=i.length;h>g;g++)d=i[g],j.push(k(a,d,c+1));return j},f=function(){var a,b;return a=this.settings.server.url,b=""+a+"/years/array","JSONP"===this.settings.server.method?(b+="?callback=getYearsCallback",i(b)):h(b,getYearsCallback)},this.getYearsCallback=function(b){var c;return c=[],b.success&&(c=b.data.sort()),g.options.timeline=wesCountry.selector.timeline({container:"#timeline",maxShownElements:10,elements:c}),g.selectorDataReady.timeline=!0,a()},b=function(){var a,b;return a=this.settings.server.url,b=""+a+"/areas/continents","JSONP"===this.settings.server.method?(b+="?callback=getCountriesCallback",i(b)):h(b,getYearsCallback)},this.getCountriesCallback=function(b){var c;return c=[],b.success&&(c=b.data),c.unshift({name:"All countries",iso3:"ALL"}),g.options.countrySelector=new wesCountry.selector.basic({data:c,onChange:null,selectedItems:["ALL"],maxSelectedItems:3,labelName:"name",valueName:"iso3",childrenName:"countries",sort:!1}),document.getElementById("country-selector").appendChild(g.options.countrySelector.render()),g.selectorDataReady.countries=!0,a()},a=function(){return g.selectorDataReady.timeline&&g.selectorDataReady.countries&&g.selectorDataReady.indicatorSelector?l():void 0},d=function(a,b,c){var d,e;return d=this.settings.server.url,e=""+d+"/observations/"+a+"/"+b+"/"+c,"JSONP"===this.settings.server.method?(e+="?callback=getObservationsCallback",i(e)):h(e,getObservationsCallback)},this.getObservationsCallback=function(a){var b;if(a.success)return b=a.data,j(b)},i=function(a){var b,c;return b=document.head,c=document.createElement("script"),c.setAttribute("src",a),b.appendChild(c),b.removeChild(c)},h=function(){},m=function(){var a,b,c;return c=g.selections.year,a=g.selections.countries,b=g.selections.indicator,settings.debug&&console.log("year: "+c+" countries: "+a+" indicator: "+b),c&&a&&b?d(b,a,c):void 0},j=function(a){var b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r;for(g=function(){var b,c,d;return c="#map",null!=(d=document.querySelector(c))&&(d.innerHTML=""),b=wesCountry.maps.createMap({container:c,borderWidth:1.5,landColour:"#E4E5D8",borderColour:"#E4E5D8",backgroundColour:"none",countries:a,colourRange:["#E5E066","#83C04C","#1B7A65","#1B4E5A","#005475"]})},g(),b="#bars",null!=(q=document.querySelector(b))&&(q.innerHTML=""),l={container:b,chartType:"bar",legend:{show:!1},margins:[8,1,0,2.5],yAxis:{margin:2,title:""},valueOnItem:{show:!1},xAxis:{values:[],title:""},groupMargin:0,series:a,mean:{show:!0},median:{show:!0}},k=a.length,f=[{r:0,g:84,b:117},{r:27,g:78,b:90},{r:27,g:122,b:101},{r:131,g:192,b:76},{r:229,g:224,b:102}],l.serieColours=[],i=0,e=f.length,k=a.length,j=k/(e-1),m=function(){r=[];for(var a=0;j>=0?j>=a:a>=j;j>=0?a++:a--)r.push(a);return r}.apply(this);e-1>i;){for(o=0,p=m.length;p>o;o++)h=m[o],c=f[i],d=f[i+1],l.serieColours.push(wesCountry.makeGradientColour(c,d,h/j*100).cssColour);i++}return l.getElementColour=function(a,b,c){return a.serieColours[c]},wesCountry.charts.chart(l),window.attachEvent?window.attachEvent("onresize",n):window.addEventListener("resize",n,!1),n=function(){return g()}},setTimeout(function(){return e()},this.settings.elapseTimeout)}).call(this);