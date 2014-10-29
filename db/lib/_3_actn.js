(function(){
  
  var 
  
  root = this,
  
  Actn = (function() {
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

  root.actn = new Actn();

  root.actn.jjv = jjv();

}).call(this);