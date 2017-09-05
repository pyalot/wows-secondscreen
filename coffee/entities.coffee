entityTypes =
	smoke: class SmokeScreen
		constructor: (@game, data) ->
			@ctx = @game.ctx
			@radius = data.radius

			[r,g,b] = [5,32,53]
			f = 0.2
			r = Math.round(r*(1-f)+255*f).toFixed(0)
			g = Math.round(g*(1-f)+255*f).toFixed(0)
			b = Math.round(b*(1-f)+255*f).toFixed(0)
			@color = "rgb(#{r}, #{g}, #{b})"

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

		update: ({@points}) -> null

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
