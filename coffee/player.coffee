shapes =
	Cruiser: new Path2D('m -8,-4 v 8 h 3.8164062 l 3.72656255,-8 z m 9.7480469,0 -3.7265625,8 H 5 L 9,0 5,-4 Z')
	Battleship: new Path2D('m -8,-4 v 8 h 1.300781 l 3.726563,-8 z m 7.232422,0 -3.726563,8 h 2.373047 L 1.605469,-4 Z M 3.8125,-4 0.085938,4 H 5 L 9,0 5,-4 Z')
	Destroyer: new Path2D('M -5,-4 6,0 -5,4 v -8')
	AirCarrier: new Path2D('m -8,-4 v 3 H 1 V -4 Z M 3,-4 V 4 H 5 L 9,0 5,-4 Z M -8,1 V 4 H 1 V 1 Z')
	ship: new Path2D('M 9,0 5,4 H -8 V -4 H 5 Z')
	self: new Path2D('M -5,-4 6,0 -5,4 -3,0 -5,-4')

exports.index = class Player
	constructor: (@game, @info, @aliveContainer, @deadContainer) ->
		@ctx = @game.ctx
		@id = @info.id
		@self = @info.self
		@alive = true

		@div = $('<div class="player"></div>')
			.appendTo(@aliveContainer)

		$('<div class="name"></div>')
			.appendTo(@div)
			.text(@info.name)

		$('<div class="ship"></div>')
			.appendTo(@div)
			.text(@info.ship.name)

		@speedDisplay = $('<div class="speed"></div>')
			.appendTo(@div)

	getTargetId: ->
		if @data?
			return @data.targeting

	draw: ->
		if not @data?
			return

		if not @data.spotted?
			return

		x = @game.getDrawX(@data.position[0])
		y = @game.getDrawY(@data.position[2])
		s = Math.sin(@data.dir)
		c = Math.cos(@data.dir)

		if @self
			@drawSelf(x, y, s, c)
		else
			@drawShip(x, y, s, c)

	drawTargetMarker: ->
		if @data?
			x = @game.getDrawX(@data.position[0])
			y = @game.getDrawY(@data.position[2])
			s = Math.sin(@data.dir)
			c = Math.cos(@data.dir)

			@ctx.strokeStyle = 'rgba(255,255,255,0.2)'
			@ctx.beginPath()
			@ctx.moveTo(x, y)
			@ctx.lineTo(x+s*2000, y-c*2000)
			@ctx.stroke()

			spacing = Math.PI/10
			span = Math.PI/4 - spacing
			q = Math.PI/2


			@ctx.save()
			@ctx.translate(x, y)
			@ctx.rotate(@data.dir)

			@ctx.strokeStyle = 'rgba(255,255,255,0.8)'
			@ctx.beginPath()
			@ctx.arc(0, 0, 25, -span, span)
			@ctx.stroke()

			@ctx.beginPath()
			@ctx.arc(0, 0, 25, q-span, q+span)
			@ctx.stroke()

			@ctx.beginPath()
			@ctx.arc(0, 0, 25, 2*q-span, 2*q+span)
			@ctx.stroke()

			@ctx.beginPath()
			@ctx.arc(0, 0, 25, 3*q-span, 3*q+span)
			@ctx.stroke()

			@ctx.beginPath()
			@ctx.moveTo(14, +14)
			@ctx.lineTo(21, +21)
			@ctx.stroke()

			@ctx.beginPath()
			@ctx.moveTo(-14, -14)
			@ctx.lineTo(-21, -21)
			@ctx.stroke()

			@ctx.beginPath()
			@ctx.moveTo(+14, -14)
			@ctx.lineTo(+21, -21)
			@ctx.stroke()

			@ctx.beginPath()
			@ctx.moveTo(-14, +14)
			@ctx.lineTo(-21, +21)
			@ctx.stroke()
			@ctx.restore()

	drawSelf: (x, y, s, c) ->
		if @data.alive
			color = 'white'
		else
			color = 'black'

		@ctx.strokeStyle = 'rgba(255,255,255,0.2)'
		@ctx.beginPath()
		@ctx.moveTo(x, y)
		@ctx.lineTo(x+s*2000, y-c*2000)
		@ctx.stroke()

		@ctx.fillStyle = color
		shape = shapes.self
		@ctx.save()
		@ctx.shadowColor = 'rgba(0, 0, 0, 1)'
		@ctx.shadowBlur = 10
		@ctx.translate(x, y)
		@ctx.rotate(@data.dir - Math.PI/2)
		@ctx.scale(1.2, 1.2)
		@ctx.fill(shape)
		@ctx.restore()

	drawShipShape: (x, y, s, c) ->
		if @data.alive
			if @info.team == 'ally'
				@ctx.fillStyle = '#45e9af'
			else
				if @data.spotted
					@ctx.fillStyle = '#ff3615'
				else
					@ctx.fillStyle = '#ccc'
		else
			@ctx.fillStyle = 'rgba(0,0,0,0.5)'

		shape = shapes[@info.ship.type]
		@ctx.save()
		@ctx.shadowColor = 'rgba(0, 0, 0, 1)'
		@ctx.shadowBlur = 10
		@ctx.translate(x, y)
		@ctx.rotate(@data.dir - Math.PI/2)
		@ctx.scale(0.8, 0.8)
		@ctx.fill(shape)
		@ctx.restore()

	drawShipExtra: (x, y, s, c) ->
		if @data.alive
			if @info.team == 'ally'
				@ctx.fillStyle = '#45e9af'
			else
				@ctx.fillStyle = '#ff3615'
				
			@ctx.save()
			@ctx.globalAlpha = 0.8
			@ctx.textAlign = 'center'
			@ctx.font = '500 9px "Nobile"'
			@ctx.fillText(@info.ship.short, Math.round(x), Math.round(y+18))
			@ctx.restore()

			@ctx.strokeStyle = 'rgba(255,255,255,0.2)'
			@ctx.beginPath()
			@ctx.moveTo(x, y)
			@ctx.lineTo(x+s*30, y-c*30)
			@ctx.stroke()

	drawShip: (x, y, s, c) ->
		@drawShipShape(x, y, s, c)
		@drawShipExtra(x, y, s, c)

	drawCamera: (camera) ->
		if @data and @game.ranges
			x = @game.getDrawX(@data.position[0])
			y = @game.getDrawY(@data.position[2])
			dist = @game.toMapDim(@game.ranges.vision)

			[dx,dy,dz] = camera.dir
			@ctx.strokeStyle = 'rgba(255,255,255,0.5)'
			@ctx.beginPath()
			@ctx.moveTo(x,y)
			@ctx.lineTo(x+dx*dist, y-dz*dist)
			@ctx.stroke()

	drawRanges: ->
		if @data and @game.ranges
			x = @game.getDrawX(@data.position[0])
			y = @game.getDrawY(@data.position[2])
			ranges = @game.ranges

			@drawCircle(x, y, ranges.seaVisible, 'rgba(50,128,20,0.1)', false)
			@drawCircle(x, y, ranges.seaVisible, 'rgba(50,128,20,0.5)', true)
			@drawCircle(x, y, ranges.airVisible, 'rgba(50,128,20,0.5)', true, [5, 5])
			@drawCircle(x, y, ranges.gun, 'rgba(255,255,255,0.9)')
			@drawCircle(x, y, ranges.torpedo, 'rgba(255,255,255,0.5)')

	drawCircle: (x, y, radius, color, stroke=true, dash=null) ->
		radius = @game.toMapDim(radius)
		@ctx.save()
		if dash
			@ctx.setLineDash(dash)
		@ctx.beginPath()
		@ctx.arc(x, y, radius, 0, Math.PI*2)
		if stroke
			@ctx.strokeStyle = color
			@ctx.stroke()
		else
			@ctx.fillStyle = color
			@ctx.fill()
		@ctx.restore()

	died: ->
		@div.addClass('dead')
		@div.appendTo(@deadContainer)

	update: (@data) ->
		if not @data.alive
			@alive = false
			@died()

		if @data.visible
			@speedDisplay.removeClass('hidden')
		else
			@speedDisplay.addClass('hidden')

		@speedDisplay.text @data.speed.toFixed(0) + ' kts'
		if @targeted
			@div.addClass('targeted')
		else
			@div.removeClass('targeted')