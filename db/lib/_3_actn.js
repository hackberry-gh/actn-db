global = (function() {
  return this;
}).call(null);

var Actn = (function() {
  function Actn() {}

  Actn.prototype.valueAt = function(data, key) {
    var i, keys;
    keys = key.split(".");
    for (i in keys) {
      if (data != null) {
        data = data[keys[i]];
      }
    }
    return data;
  };

  return Actn;

})();

global.actn = new Actn();

global.actn.jjv = jjv();