import BigWorld, json

class SmokeScreen:
    def __init__(self, id, entity, server):
        self.id = id
        self.server = server
        self.entity = entity
        self.points = tuple()

        self.create()

    def send(self, **data):
        self.server.send_message_to_all(json.dumps(data))

    def sendToClient(self, client, **data):
        self.server.send_message(client, json.dumps(data))

    def create(self):
        self.send(type='entity', action='create', id=self.id, entityType='smoke', radius=self.entity.radius)

    def update(self):
        points = tuple(map(tuple, self.entity.points))
        if self.points != points:
            self.points = points
            self.send(type='entity', action='update', id=self.id, entityType='smoke', points=points)

    def remove(self):
        self.send(type='entity', action='remove', id=self.id, entityType='smoke')

    def informClient(self, client):
        self.sendToClient(client, type='entity', action='create', id=self.id, entityType='smoke', radius=self.entity.radius)
        self.sendToClient(client, type='entity', action='update', id=self.id, entityType='smoke', points=self.points)


tracked = {
    'SmokeScreen': SmokeScreen
}

class Entities:
    def __init__(self, server):
        self.server = server
        self.entities = {}

    def update(self):
        for id, entity in BigWorld.entities.items():
            cls = tracked.get(entity.__class__.__name__)
            if cls:
                if id not in self.entities:
                    instance = self.entities[id] = cls(id, entity, self.server)
        
        for id, entity in self.entities.items():
            if id not in BigWorld.entities.keys():
                entity.remove()
                del self.entities[id]

        for entity in self.entities.values():
            entity.update()

    def informClient(self, client):
        for entity in self.entities.values():
            entity.informClient(client)
        
                