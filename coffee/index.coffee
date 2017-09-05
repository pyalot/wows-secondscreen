Game = sys.import('game')

$ ->
	connection = new WebSocket("ws://#{document.location.hostname}:2503/")

	game = new Game()

	connection.onmessage = ({data}) ->
		data = JSON.parse(data)
		switch data.type
			when 'info'
				game.info(data.data)
			when 'update'
				game.update(data.data)