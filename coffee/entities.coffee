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

exports.index = class Entities
	constructor: (@game) ->
		console.log 'here'
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
