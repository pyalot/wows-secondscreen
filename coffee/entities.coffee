entityTypes =
	smoke: class SmokeScreen
		constructor: (@game, data) ->
			@ctx = @game.ctx
			@radius = data.data.radius
			@color = 'rgba(255,255,255,0.1)'

		draw: ->
			if @points?
				@ctx.save()
				@ctx.fillStyle = @color
				for [x,y] in @points
					x = @game.getDrawX(x)
					y = @game.getDrawY(y)

					@ctx.beginPath()
					@ctx.arc(x, y, @radius, 0, Math.PI*2)
					@ctx.fill()
				@ctx.restore()

		update: (data) ->
			@points = data.data

	shot: class Shot
		constructor: (@game, data) ->
			@ctx = @game.ctx
			@data = data.data
			@startTime = performance.now()/1000
			
		draw: ->
			#offset = @game.mapHeight*(70/800)
			x0 = @game.getDrawX(@data.origin[0])
			y0 = @game.getDrawY(@data.origin[2])
			x1 = @game.getDrawX(@data.target[0])
			y1 = @game.getDrawY(@data.target[2])

			xd = @data.dir[0]
			yd = -@data.dir[2]
			l = Math.sqrt(xd*xd + yd*yd)
			xd/=l
			yd/=l
			dist = @game.toMapDim(@data.distance)

			###
			@ctx.save()
			@ctx.strokeStyle = 'red'
			#@ctx.strokeStyle = 'rgba(255,255,255,0.1)'
			@ctx.beginPath()
			@ctx.moveTo(x0, y0+2)
			@ctx.lineTo(x1, y1+2)
			@ctx.stroke()
			@ctx.restore()
			###

			@ctx.save()
			#@ctx.strokeStyle = 'green'
			@ctx.strokeStyle = 'rgba(255,255,255,0.1)'
			@ctx.beginPath()
			@ctx.moveTo(x0, y0)
			@ctx.lineTo(x0+xd*dist, y0+yd*dist)
			@ctx.stroke()
			@ctx.restore()

			now = performance.now()/1000
			f = (now - @startTime)/(@data.time+0.4)
			#x = x0 + xd*dist*f
			#y = y0 + yd*dist*f
			x = x0*(1-f) + x1*f
			y = y0*(1-f) + y1*f

			if @data.type == 'AP'
				@ctx.fillStyle = '#57aeff'
			else
				@ctx.fillStyle = 'red'
			@ctx.beginPath()
			@ctx.arc(x, y, 1, 0, Math.PI*2)
			@ctx.fill()
			@ctx.fill()

		update: ->
			null

	torpedo: class Torpedo
		shape: new Path2D('M -3 -1 L -3.3535156 -0.85351562 L -3.5 -0.5 L -3.5 0 L -3.5 0.5 L -3.3535156 0.85351562 L -3 1 L -1 1 L 1 1 L 1.3535156 0.85351562 L 1.5 0.5 L 1.5 0 L 1.5 -0.5 L 1.3535156 -0.85351562 L 1 -1 L -1 -1 L -3 -1 z M 2.5 -1 L 2.1464844 -0.85351562 L 2 -0.5 L 2 0 L 2 0.5 L 2.1464844 0.85351562 L 2.5 1 L 2.75 1 L 3 1 L 3.3535156 0.85351562 L 3.5 0.5 L 3.5 0 L 3.5 -0.5 L 3.3535156 -0.85351562 L 3 -1 L 2.75 -1 L 2.5 -1 z ')

		constructor: (@game, data) ->
			@ctx = @game.ctx
			@data = data.data
			@startPosition = @position = @data.position
			@direction = @data.direction
			@speed = @data.speed
			@startTime = performance.now()/1000

			xd = @direction[0]
			yd = @direction[2]
			l = Math.sqrt(xd*xd + yd*yd)
			@xd = xd/l; @yd = yd/l
			@dir = Math.atan2(@xd, @yd)

			@grad= @ctx.createLinearGradient(0, 0, -200, 0);
			@grad.addColorStop(0, "rgba(255,0,0,0.8)");
			@grad.addColorStop(1, "rgba(255,0,0,0");

		draw: ->
			delta = performance.now()/1000 - @startTime

			x0 = @startPosition[0]
			y0 = @startPosition[2]

			#x1 = @game.getDrawX(@position[0])
			#y1 = @game.getDrawY(@position[2])

			x2 = @game.getDrawX(x0 + @xd*@speed*delta)
			y2 = @game.getDrawY(y0 + @yd*@speed*delta)

			@ctx.save()
			@ctx.translate(x2, y2)
			@ctx.rotate(@dir + Math.PI/2)
			@ctx.fillStyle = 'red'
			@ctx.fill(@shape)
			@ctx.strokeStyle = @grad
			@ctx.beginPath()
			@ctx.moveTo(0,0)
			@ctx.lineTo(-200, 0)
			@ctx.stroke()

			@ctx.restore()

		update: ({data}) ->
			@position = data

	plane: class Plane
		shape: new Path2D('m -3.7500001,-0.25000057 0.25,-1.25000003 h 0.5 L -2.75,-0.50000057 -0.75000013,-0.74998057 6.9999999e-8,-3.4999806 H 0.7499997 l 0.25,2.75000003 0.75,0.25 v 0.9999998 l -0.75,0.25 -0.25,2.74998017 H 9.7e-7 L -0.75000003,0.74999923 -2.75,0.49999923 -3.0000001,1.4999993 h -0.5 l -0.25,-1.25000007 z')
		constructor: (@game, {data}) ->
			@ctx = @game.ctx
			@info = data

		draw: ->
			if @position?
				x = @game.getDrawX(@position[0])
				y = @game.getDrawY(@position[2])

				@ctx.save()
				@ctx.translate(x, y)
				@ctx.scale(1.7, 1.7)
				@ctx.rotate(@dir - Math.PI/2)
				if @info.team == 'ally'
					@ctx.fillStyle = '#45e9af'
				else
					@ctx.fillStyle = '#ff3615'
				@ctx.fill(@shape)
				@ctx.restore()

		update: ({data}) ->
			@position = data.position
			@direction = data.direction
			@count = data.count

			xd = @direction[0]
			yd = @direction[2]
			l = Math.sqrt(xd*xd + yd*yd)
			@xd = xd/l; @yd = yd/l
			@dir = Math.atan2(@xd, @yd)

exports.index = class Entities
	constructor: (@game) ->
		@entities = {}

	message: (data) ->
		switch data.action
			when 'create'
				@entities[data.id] = new entityTypes[data.entityType](@game, data)
			when 'update'
				@entities[data.id].update(data)
			when 'remove'
				delete @entities[data.id]

	draw: ->
		for id, entity of @entities
			entity.draw()
