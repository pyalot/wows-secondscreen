(function(){
var File, moduleManager;

Function.prototype.property = function(prop, desc) {
  return Object.defineProperty(this.prototype, prop, desc);
};

moduleManager = {
  File: File = (function() {
    function File(manager, absPath) {
      this.manager = manager;
      this.absPath = absPath;
      if (this.manager.files[this.absPath] == null) {
        throw new Error("file does not exist: " + this.absPath);
      }
    }

    File.prototype.read = function() {
      return this.manager.files[this.absPath];
    };

    return File;

  })(),
  modules: {},
  files: {},
  module: function(name, closure) {
    return this.modules[name] = {
      closure: closure,
      instance: null
    };
  },
  text: function(name, content) {
    return this.files[name] = content;
  },
  index: function() {
    this.getLocation();
    return this["import"]('/index');
  },
  getLocation: function() {
    var script, scripts;
    if (self.document != null) {
      scripts = document.getElementsByTagName('script');
      script = scripts[scripts.length - 1];
      this.script = script.src;
    } else {
      this.script = self.location.href;
    }
    return this.location = this.script.slice(0, this.script.lastIndexOf('/') + 1);
  },
  abspath: function(fromName, pathName) {
    var base, baseName, path;
    if (pathName === '.') {
      pathName = '';
    }
    baseName = fromName.split('/');
    baseName.pop();
    baseName = baseName.join('/');
    if (pathName[0] === '/') {
      return pathName;
    } else {
      path = pathName.split('/');
      if (baseName === '/') {
        base = [''];
      } else {
        base = baseName.split('/');
      }
      while (base.length > 0 && path.length > 0 && path[0] === '..') {
        base.pop();
        path.shift();
      }
      if (base.length === 0 || path.length === 0 || base[0] !== '') {
        throw new Error("Invalid path: " + (base.join('/')) + "/" + (path.join('/')));
      }
      return (base.join('/')) + "/" + (path.join('/'));
    }
  },
  "import": function(moduleName) {
    var exports, module, require, sys;
    if (moduleName != null) {
      module = this.modules[moduleName];
      if (module === void 0) {
        module = this.modules[moduleName + '/index'];
        if (module != null) {
          moduleName = moduleName + '/index';
        } else {
          throw new Error('Module not found: ' + moduleName);
        }
      }
      if (module.instance === null) {
        require = (function(_this) {
          return function(requirePath) {
            var path;
            path = _this.abspath(moduleName, requirePath);
            return _this["import"](path);
          };
        })(this);
        exports = {};
        sys = {
          script: this.script,
          location: this.location,
          "import": (function(_this) {
            return function(requirePath) {
              var path;
              path = _this.abspath(moduleName, requirePath);
              return _this["import"](path);
            };
          })(this),
          file: (function(_this) {
            return function(path) {
              path = _this.abspath(moduleName, path);
              return new _this.File(_this, path);
            };
          })(this),
          File: File
        };
        module.closure(exports, sys);
        if (exports.index != null) {
          module.instance = exports.index;
        } else {
          module.instance = exports;
        }
      }
      return module.instance;
    } else {
      throw new Error('no module name provided');
    }
  }
};
moduleManager.module('/index', function(exports,sys){
var Game;

Game = sys["import"]('game');

$(function() {
  var connection, game;
  connection = new WebSocket("ws://" + document.location.hostname + ":2503/");
  game = new Game();
  return connection.onmessage = function(arg) {
    var data;
    data = arg.data;
    data = JSON.parse(data);
    return game.message(data);
  };
});
});
moduleManager.module('/game', function(exports,sys){
var Entities, Game, Player,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Player = sys["import"]('player');

Entities = sys["import"]('entities');

exports.index = Game = (function() {
  function Game() {
    this.raf = bind(this.raf, this);
    var mapdiv;
    this.sidebar = $('<div class="sidebar"></div>').appendTo('body');
    $('<h1 class="allies">My Team</h1>').appendTo(this.sidebar);
    this.alliesAlive = $('<div class="players allies"></div>').appendTo(this.sidebar);
    this.alliesDead = $('<div class="players allies"></div>').appendTo(this.sidebar);
    $('<h1 class="enemies">Enemies</h1>').appendTo(this.sidebar);
    this.enemiesAlive = $('<div class="players enemies"></div>').appendTo(this.sidebar);
    this.enemiesDead = $('<div class="players enemies"></div>').appendTo(this.sidebar);
    mapdiv = $('<div class="map"></div>').appendTo('body');
    this.canvas = $('<canvas></canvas>').appendTo(mapdiv)[0];
    this.ctx = this.canvas.getContext('2d');
    this.playersByID = {};
    this.playersByShipID = {};
    this.players = [];
    this.entities = new Entities(this);
    this.raf();
  }

  Game.prototype.info = function(data) {
    var i, len, player, playerData, ref;
    this.playersByID = {};
    this.playersByShipID = {};
    this.players = [];
    if (data.inMatch) {
      this.canvas.style.backgroundImage = "url(pkg/" + data.map.name + "/minimap.png)";
      this.inMatch = true;
      this.mapWidth = data.map.border.high[0] - data.map.border.low[0];
      this.mapHeight = data.map.border.high[2] - data.map.border.low[2];
      this.mapX = data.map.border.low[0];
      this.mapY = data.map.border.low[2];
      console.log(this.mapHeight);
      ref = data.players;
      for (i = 0, len = ref.length; i < len; i++) {
        playerData = ref[i];
        if (playerData.team === 'ally') {
          player = new Player(this, playerData, this.alliesAlive, this.alliesDead);
        } else {
          player = new Player(this, playerData, this.enemiesAlive, this.enemiesDead);
        }
        if (player.self) {
          this.self = player;
        }
        this.players.push(player);
        this.playersByID[player.id] = player;
        this.playersByShipID[playerData.ship.id] = player;
      }
    } else {
      this.canvas.style.backgroundImage = 'none';
      this.inMatch = false;
      this.self = null;
      this.alliesDead.empty();
      this.alliesAlive.empty();
      this.enemiesDead.empty();
      this.enemiesAlive.empty();
    }
  };

  Game.prototype.message = function(data) {
    switch (data.type) {
      case 'info':
        return this.info(data.data);
      case 'update':
        this.camera = data.data.camera;
        return this.updatePlayers(data.data.players);
      case 'entity':
        return this.entities.message(data);
    }
  };

  Game.prototype.updatePlayers = function(data) {
    var i, item, len, player;
    for (i = 0, len = data.length; i < len; i++) {
      item = data[i];
      player = this.playersByID[item.id];
      if (player != null) {
        player.update(item);
      }
    }
  };

  Game.prototype.drawPlayers = function() {
    var i, j, len, len1, player, ref, ref1, target, targetId;
    ref = this.players;
    for (i = 0, len = ref.length; i < len; i++) {
      player = ref[i];
      player.targeted = false;
    }
    targetId = this.self.getTargetId();
    target = this.playersByShipID[targetId];
    if (target != null) {
      target.targeted = true;
      target.drawTargetMarker();
    }
    ref1 = this.players;
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      player = ref1[j];
      player.draw();
    }
  };

  Game.prototype.drawBorder = function() {
    var x0, x1, y0, y1;
    x0 = this.drawAreaX;
    y0 = this.drawAreaY;
    x1 = x0 + this.drawAreaSize;
    y1 = y0 + this.drawAreaSize;
    this.ctx.strokeStyle = 'rgba(255,255,255,0.25)';
    this.ctx.beginPath();
    this.ctx.moveTo(x0, y0);
    this.ctx.lineTo(x1, y0);
    this.ctx.lineTo(x1, y1);
    this.ctx.lineTo(x0, y1);
    this.ctx.closePath();
    return this.ctx.stroke();
  };

  Game.prototype.drawCamera = function() {
    if (this.self && this.camera) {
      return this.self.drawCamera(this.camera);
    }
  };

  Game.prototype.raf = function() {
    var height, width;
    width = this.canvas.clientWidth;
    height = this.canvas.clientHeight;
    if (width !== this.canvas.width || height !== this.canvas.height) {
      this.drawAreaSize = Math.min(width, height);
      this.drawAreaX = (width / 2) - this.drawAreaSize / 2;
      this.drawAreaY = (height / 2) - this.drawAreaSize / 2;
      this.canvas.width = width;
      this.canvas.height = height;
    }
    this.width = width;
    this.height = height;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    if (this.inMatch) {
      this.drawBorder();
      this.entities.draw();
      this.drawCamera();
      this.drawPlayers();
    }
    return requestAnimationFrame(this.raf);
  };

  Game.prototype.getDrawX = function(x) {
    x = (x - this.mapX) / this.mapWidth;
    x = this.drawAreaX + x * this.drawAreaSize;
    return x;
  };

  Game.prototype.getDrawY = function(y) {
    y = 1.0 - (y - this.mapY) / this.mapHeight;
    y = this.drawAreaY + y * this.drawAreaSize;
    return y;
  };

  Game.prototype.toMapDim = function(value) {
    return value * (this.drawAreaSize / this.mapHeight);
  };

  return Game;

})();
});
moduleManager.module('/player', function(exports,sys){
var Player, shapes;

shapes = {
  Cruiser: new Path2D('m -8,-4 v 8 h 3.8164062 l 3.72656255,-8 z m 9.7480469,0 -3.7265625,8 H 5 L 9,0 5,-4 Z'),
  Battleship: new Path2D('m -8,-4 v 8 h 1.300781 l 3.726563,-8 z m 7.232422,0 -3.726563,8 h 2.373047 L 1.605469,-4 Z M 3.8125,-4 0.085938,4 H 5 L 9,0 5,-4 Z'),
  Destroyer: new Path2D('M -5,-4 6,0 -5,4 v -8'),
  AirCarrier: new Path2D('m -8,-4 v 3 H 1 V -4 Z M 3,-4 V 4 H 5 L 9,0 5,-4 Z M -8,1 V 4 H 1 V 1 Z'),
  ship: new Path2D('M 9,0 5,4 H -8 V -4 H 5 Z'),
  self: new Path2D('M -5,-4 6,0 -5,4 -3,0 -5,-4')
};

exports.index = Player = (function() {
  function Player(game, info, aliveContainer, deadContainer) {
    this.game = game;
    this.info = info;
    this.aliveContainer = aliveContainer;
    this.deadContainer = deadContainer;
    this.ctx = this.game.ctx;
    this.id = this.info.id;
    this.self = this.info.self;
    this.alive = true;
    this.div = $('<div class="player"></div>').appendTo(this.aliveContainer);
    $('<div class="name"></div>').appendTo(this.div).text(this.info.name);
    $('<div class="ship"></div>').appendTo(this.div).text(this.info.ship.name);
    this.speedDisplay = $('<div class="speed"></div>').appendTo(this.div);
  }

  Player.prototype.getTargetId = function() {
    if (this.data != null) {
      return this.data.targeting;
    }
  };

  Player.prototype.draw = function() {
    var c, s, x, y;
    if (this.data == null) {
      return;
    }
    if (this.data.spotted == null) {
      return;
    }
    x = this.game.getDrawX(this.data.position[0]);
    y = this.game.getDrawY(this.data.position[2]);
    s = Math.sin(this.data.dir);
    c = Math.cos(this.data.dir);
    if (this.self) {
      return this.drawSelf(x, y, s, c);
    } else {
      return this.drawShip(x, y, s, c);
    }
  };

  Player.prototype.drawTargetMarker = function() {
    var c, q, s, spacing, span, x, y;
    if (this.data != null) {
      x = this.game.getDrawX(this.data.position[0]);
      y = this.game.getDrawY(this.data.position[2]);
      s = Math.sin(this.data.dir);
      c = Math.cos(this.data.dir);
      this.ctx.strokeStyle = 'rgba(255,255,255,0.2)';
      this.ctx.beginPath();
      this.ctx.moveTo(x, y);
      this.ctx.lineTo(x + s * 2000, y - c * 2000);
      this.ctx.stroke();
      spacing = Math.PI / 10;
      span = Math.PI / 4 - spacing;
      q = Math.PI / 2;
      this.ctx.save();
      this.ctx.translate(x, y);
      this.ctx.rotate(this.data.dir);
      this.ctx.strokeStyle = 'rgba(255,255,255,0.8)';
      this.ctx.beginPath();
      this.ctx.arc(0, 0, 25, -span, span);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.arc(0, 0, 25, q - span, q + span);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.arc(0, 0, 25, 2 * q - span, 2 * q + span);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.arc(0, 0, 25, 3 * q - span, 3 * q + span);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.moveTo(14, +14);
      this.ctx.lineTo(21, +21);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.moveTo(-14, -14);
      this.ctx.lineTo(-21, -21);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.moveTo(+14, -14);
      this.ctx.lineTo(+21, -21);
      this.ctx.stroke();
      this.ctx.beginPath();
      this.ctx.moveTo(-14, +14);
      this.ctx.lineTo(-21, +21);
      this.ctx.stroke();
      return this.ctx.restore();
    }
  };

  Player.prototype.drawSelf = function(x, y, s, c) {
    var color, shape;
    if (this.data.alive) {
      color = 'white';
    } else {
      color = 'black';
    }
    this.ctx.strokeStyle = 'rgba(255,255,255,0.2)';
    this.ctx.beginPath();
    this.ctx.moveTo(x, y);
    this.ctx.lineTo(x + s * 2000, y - c * 2000);
    this.ctx.stroke();
    this.ctx.fillStyle = color;
    shape = shapes.self;
    this.ctx.save();
    this.ctx.translate(x, y);
    this.ctx.rotate(this.data.dir - Math.PI / 2);
    this.ctx.fill(shape);
    return this.ctx.restore();
  };

  Player.prototype.drawShipShape = function(x, y, s, c) {
    var shape;
    if (this.data.alive) {
      if (this.info.team === 'ally') {
        this.ctx.fillStyle = '#45e9af';
      } else {
        if (this.data.spotted) {
          this.ctx.fillStyle = '#ff3615';
        } else {
          this.ctx.fillStyle = '#ccc';
        }
      }
    } else {
      this.ctx.fillStyle = 'rgba(0,0,0,0.5)';
    }
    shape = shapes[this.info.ship.type];
    this.ctx.save();
    this.ctx.translate(x, y);
    this.ctx.rotate(this.data.dir - Math.PI / 2);
    this.ctx.fill(shape);
    return this.ctx.restore();
  };

  Player.prototype.drawShipExtra = function(x, y, s, c) {
    if (this.data.alive) {
      if (this.info.team === 'ally') {
        this.ctx.fillStyle = '#45e9af';
      } else {
        this.ctx.fillStyle = '#ff3615';
      }
      this.ctx.save();
      this.ctx.globalAlpha = 0.8;
      this.ctx.textAlign = 'center';
      this.ctx.font = '500 9px "Nobile"';
      this.ctx.fillText(this.info.ship.short, Math.round(x), Math.round(y + 18));
      this.ctx.restore();
      this.ctx.strokeStyle = 'rgba(255,255,255,0.2)';
      this.ctx.beginPath();
      this.ctx.moveTo(x, y);
      this.ctx.lineTo(x + s * 30, y - c * 30);
      return this.ctx.stroke();
    }
  };

  Player.prototype.drawShip = function(x, y, s, c) {
    this.drawShipShape(x, y, s, c);
    return this.drawShipExtra(x, y, s, c);
  };

  Player.prototype.drawCamera = function(camera) {
    var dx, dy, dz, ref, x, y;
    if (this.data) {
      x = this.game.getDrawX(this.data.position[0]);
      y = this.game.getDrawY(this.data.position[2]);
      ref = camera.dir, dx = ref[0], dy = ref[1], dz = ref[2];
      this.ctx.strokeStyle = 'rgba(255,255,255,0.5)';
      this.ctx.beginPath();
      this.ctx.moveTo(x, y);
      this.ctx.lineTo(x + dx * 1000, y - dz * 1000);
      return this.ctx.stroke();
    }
  };

  Player.prototype.died = function() {
    this.div.addClass('dead');
    return this.div.appendTo(this.deadContainer);
  };

  Player.prototype.update = function(data) {
    this.data = data;
    if (!this.data.alive) {
      this.alive = false;
      this.died();
    }
    if (this.data.visible) {
      this.speedDisplay.removeClass('hidden');
    } else {
      this.speedDisplay.addClass('hidden');
    }
    this.speedDisplay.text(this.data.speed.toFixed(0) + ' kts');
    if (this.targeted) {
      return this.div.addClass('targeted');
    } else {
      return this.div.removeClass('targeted');
    }
  };

  return Player;

})();
});
moduleManager.module('/entities', function(exports,sys){
var Entities, Shot, SmokeScreen, entityTypes;

entityTypes = {
  smoke: SmokeScreen = (function() {
    function SmokeScreen(game, data) {
      var b, f, g, r, ref;
      this.game = game;
      this.ctx = this.game.ctx;
      this.radius = data.data.radius;
      ref = [5, 32, 53], r = ref[0], g = ref[1], b = ref[2];
      f = 0.2;
      r = Math.round(r * (1 - f) + 255 * f).toFixed(0);
      g = Math.round(g * (1 - f) + 255 * f).toFixed(0);
      b = Math.round(b * (1 - f) + 255 * f).toFixed(0);
      this.color = 'rgba(255,255,255,0.1)';
    }

    SmokeScreen.prototype.draw = function() {
      var i, len, ref, ref1, x, y;
      if (this.points != null) {
        this.ctx.save();
        this.ctx.fillStyle = this.color;
        ref = this.points;
        for (i = 0, len = ref.length; i < len; i++) {
          ref1 = ref[i], x = ref1[0], y = ref1[1];
          x = this.game.getDrawX(x);
          y = this.game.getDrawY(y);
          this.ctx.beginPath();
          this.ctx.arc(x, y, this.radius, 0, Math.PI * 2);
          this.ctx.fill();
        }
        return this.ctx.restore();
      }
    };

    SmokeScreen.prototype.update = function(data) {
      return this.points = data.data;
    };

    return SmokeScreen;

  })(),
  shot: Shot = (function() {
    function Shot(game, data) {
      this.game = game;
      this.ctx = this.game.ctx;
      this.data = data.data;
      this.startTime = performance.now() / 1000;
    }

    Shot.prototype.draw = function() {
      var dist, f, l, now, x, x0, x1, xd, y, y0, y1, yd;
      x0 = this.game.getDrawX(this.data.origin[0]);
      y0 = this.game.getDrawY(this.data.origin[2]);
      x1 = this.game.getDrawX(this.data.target[0]);
      y1 = this.game.getDrawY(this.data.target[2]);
      xd = this.data.dir[0];
      yd = -this.data.dir[2];
      l = Math.sqrt(xd * xd + yd * yd);
      xd /= l;
      yd /= l;
      dist = this.game.toMapDim(this.data.distance);

      /*
      			@ctx.save()
      			@ctx.strokeStyle = 'red'
      			#@ctx.strokeStyle = 'rgba(255,255,255,0.1)'
      			@ctx.beginPath()
      			@ctx.moveTo(x0, y0+2)
      			@ctx.lineTo(x1, y1+2)
      			@ctx.stroke()
      			@ctx.restore()
       */
      this.ctx.save();
      this.ctx.strokeStyle = 'rgba(255,255,255,0.1)';
      this.ctx.beginPath();
      this.ctx.moveTo(x0, y0);
      this.ctx.lineTo(x0 + xd * dist, y0 + yd * dist);
      this.ctx.stroke();
      this.ctx.restore();
      now = performance.now() / 1000;
      f = (now - this.startTime) / (this.data.time + 0.4);
      x = x0 * (1 - f) + x1 * f;
      y = y0 * (1 - f) + y1 * f;
      if (this.data.type === 'AP') {
        this.ctx.fillStyle = '#57aeff';
      } else {
        this.ctx.fillStyle = 'red';
      }
      this.ctx.beginPath();
      this.ctx.arc(x, y, 1, 0, Math.PI * 2);
      this.ctx.fill();
      return this.ctx.fill();
    };

    Shot.prototype.update = function() {
      return null;
    };

    return Shot;

  })()
};

exports.index = Entities = (function() {
  function Entities(game) {
    this.game = game;
    console.log('here');
    this.entities = {};
  }

  Entities.prototype.message = function(data) {
    switch (data.action) {
      case 'create':
        return this.entities[data.id] = new entityTypes[data.entityType](this.game, data);
      case 'update':
        return this.entities[data.id].update(data);
      case 'remove':
        return delete this.entities[data.id];
    }
  };

  Entities.prototype.draw = function() {
    var entity, id, ref, results;
    ref = this.entities;
    results = [];
    for (id in ref) {
      entity = ref[id];
      results.push(entity.draw());
    }
    return results;
  };

  return Entities;

})();
});
moduleManager.index();
})();

//# sourceMappingURL=./script.js.json