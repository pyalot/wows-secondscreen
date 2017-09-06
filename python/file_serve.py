import os
import Lesta

types = {
    'js': 'application/javascript',
    'html': 'text/html',
    'css': 'text/css',
    'json': 'application/json',
    'svg': 'image/svg+xml',
    'woff2': 'application/font-woff2',
    'png': 'image/png',
}

def notFound(environ, start_response):
    start_response('404 Not Found', [
        ('Content-Type', 'text/plain')
    ])
    return ['Not Found']

def readFile(path, environ, start_response):
    ext = os.path.splitext(path)[1][1:]
    mime = types.get(ext, 'application/octet-stream')
    content = open(path, 'rb').read()
    start_response('200 OK', [
        ('Content-Type', mime),
        ('Content-Length', str(len(content))),
    ])
    return [content]

def readFromPkg(path, environ, start_response):
    ext = os.path.splitext(path)[1][1:]
    mime = types.get(ext, 'application/octet-stream')
    path = path[4:]
    content = Lesta.readTextFile(path)
    start_response('200 OK', [
        ('Content-Type', mime),
        ('Content-Length', str(len(content))),
    ])
    return [content]

def getFile(environ, start_response):
    path = environ['PATH_INFO']
    path = path.rstrip('/')[1:]

    if path.startswith('pkg/'):
        return readFromPkg(path, environ, start_response)
    else:
        if path == '':
            path = 'index.html'

        path = os.path.join(mapi.package, 'www', path)

        if os.path.exists(path):
            if os.path.isdir(path):
                path = os.path.join(path, 'index.html')
                if path.exists(path):
                    return readFile(path, environ, start_response)
                else:
                    return notFound(environ, start_response)
            else:
                return readFile(path, environ, start_response)
        else:
            return notFound(environ, start_response)
