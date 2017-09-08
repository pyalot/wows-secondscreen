Player = sys.import 'player'
Entities = sys.import 'entities'

exports.index = class Game
	constructor: ->
		@sidebar = $('<div class="sidebar"></div>').appendTo('body')

		$('<h1 class="allies">My Team</h1>')
			.appendTo(@sidebar)
		@alliesAlive = $('<div class="players allies"></div>')
			.appendTo(@sidebar)
		@alliesDead = $('<div class="players allies"></div>')
			.appendTo(@sidebar)

		$('<h1 class="enemies">Enemies</h1>')
			.appendTo(@sidebar)
		@enemiesAlive = $('<div class="players enemies"></div>')
			.appendTo(@sidebar)
		@enemiesDead = $('<div class="players enemies"></div>')
			.appendTo(@sidebar)

		mapdiv = $('<div class="map"></div>').appendTo('body')
		@canvas = $('<canvas></canvas>').appendTo(mapdiv)[0]
		@ctx = @canvas.getContext('2d')

		@playersByID = {}
		@playersByShipID = {}
		@players = []

		@entities = new Entities(@)

		@raf()

	info: (data) ->
		@playersByID = {}
		@playersByShipID = {}
		@players = []
		if data.inMatch
			@canvas.style.backgroundImage = "url(pkg/#{data.map.name}/minimap.png)";
			@inMatch = true
			@mapWidth = data.map.border.high[0] - data.map.border.low[0]
			@mapHeight = data.map.border.high[2] - data.map.border.low[2]
			@mapX = data.map.border.low[0]
			@mapY = data.map.border.low[2]

			for playerData in data.players
				if playerData.team == 'ally'
					player = new Player(@, playerData, @alliesAlive, @alliesDead)
				else
					player = new Player(@, playerData, @enemiesAlive, @enemiesDead)

				if player.self
					@self = player

				@players.push(player)
				@playersByID[player.id] = player
				@playersByShipID[playerData.ship.id] = player
		else
			@canvas.style.backgroundImage = 'none';
			@inMatch = false
			@self = null
			@alliesDead.empty()
			@alliesAlive.empty()
			@enemiesDead.empty()
			@enemiesAlive.empty()
		return

	message: (data) ->
		switch data.type
			when 'info'
				@info(data.data)
			when 'update'
				@camera = data.data.camera
				@ranges = data.data.ranges
				@updatePlayers(data.data.players)
			when 'entity'
				@entities.message(data)

	updatePlayers: (data) ->
		for item in data
			player = @playersByID[item.id]
			if player?
				player.update(item)
		return

	drawPlayers: ->
		for player in @players
			player.targeted = false

		targetId = @self.getTargetId()
		target = @playersByShipID[targetId]
		if target?
			target.targeted = true
			target.drawTargetMarker()

		for player in @players
			player.draw()
		return

	drawBorder: ->
		x0 = @drawAreaX
		y0 = @drawAreaY
		x1 = x0 + @drawAreaSize
		y1 = y0 + @drawAreaSize

		@ctx.strokeStyle = 'rgba(255,255,255,0.25)'
		@ctx.beginPath()
		@ctx.moveTo(x0, y0)
		@ctx.lineTo(x1, y0)
		@ctx.lineTo(x1, y1)
		@ctx.lineTo(x0, y1)
		@ctx.closePath()
		@ctx.stroke()

	drawCamera: ->
		if @self and @camera
			@self.drawCamera(@camera)

	drawRanges: ->
		if @self then @self.drawRanges()

	raf: =>
		width = @canvas.clientWidth
		height = @canvas.clientHeight

		if width != @canvas.width or height != @canvas.height
			@drawAreaSize = Math.min(width, height)
			@drawAreaX = (width/2) - @drawAreaSize/2
			@drawAreaY = (height/2) - @drawAreaSize/2

			@canvas.width = width
			@canvas.height = height

		@width = width
		@height = height

		@ctx.clearRect(0, 0, @canvas.width, @canvas.height)

		if @inMatch
			@drawBorder()
			@drawRanges()
			@entities.draw('torpedo')
			@entities.draw('smoke')
			@drawCamera()
			@drawPlayers()
			@entities.draw('plane')
			@entities.draw('shot')

		requestAnimationFrame(@raf)

	getDrawX: (x) ->
		x = (x-@mapX)/@mapWidth
		x = @drawAreaX + x*@drawAreaSize
		return x

	getDrawY: (y) ->
		y = 1.0 - (y-@mapY)/@mapHeight
		y = @drawAreaY + y*@drawAreaSize
		return y

	toMapDim: (value) ->
		return value * (@drawAreaSize/@mapHeight)