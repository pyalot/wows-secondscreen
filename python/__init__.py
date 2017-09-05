import thread, traceback, sys, time
from wsgiref import simple_server
import wsgiref.simple_server

websocket_server = mapi.require('websocket_server')
gameAPI = mapi.require('game')
file_serve = mapi.require('file_serve')

server = None
game = None

def app(environ, start_response):
    try:
        return file_serve.getFile(environ, start_response)
    except:
        start_response('500 Server Error', [
            ('Content-Type', 'text/plain')
        ])
        return [traceback.format_exc()]

class RequestHandler(simple_server.WSGIRequestHandler):
    def address_string(self):
        return self.client_address[0]

    def log_request(*args, **kwargs):
        pass

def httpd():
    httpd = simple_server.make_server('', 2502, app, handler_class=RequestHandler)
    httpd.serve_forever()

def connect(client, server):
    game.informClient(client)

def disconnect(client, server):
    pass

def message(client, server, message):
    pass

def websocket():
    try:
        global server, game
        server = websocket_server.WebsocketServer(port=2503, host='0.0.0.0')
        game = gameAPI.Game(server)
        server.set_fn_new_client(connect)
        server.set_fn_message_received(message)
        server.set_fn_client_left(disconnect)
        server.run_forever()
    except:
        mapi.log_exc()

def update():
    while 1:
        if game:
            try:
                game.update()
            except:
                mapi.log_exc()
        time.sleep(0.1)

thread.start_new_thread(httpd, ())
thread.start_new_thread(websocket, ())
thread.start_new_thread(update, ())