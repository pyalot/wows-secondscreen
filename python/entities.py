import BigWorld, json

class Entity:
    def __init__(self, server):
        self.server = server

    def send(self, **data):
        self.server.send_message_to_all(json.dumps(data))

    def sendToClient(self, client, **data):
        self.server.send_message(client, json.dumps(data))

    def create(self):
        self.send(type='entity', action='create', id=self.id, entityType=self.name, data=self.initialData())

    def update(self):
        if self.updateState():
            self.send(type='entity', action='update', id=self.id, entityType=self.name, data=self.state())

    def informClient(self, client):
        self.create()
        self.send(type='entity', action='update', id=self.id, entityType=self.name, data=self.state())

    def remove(self):
        self.send(type='entity', action='remove', id=self.id, entityType=self.name)

class SmokeScreen(Entity):
    name = 'smoke'

    def __init__(self, id, entity, server, entities):
        Entity.__init__(self, server)
        self.id = id
        self.entity = entity
        self.points = tuple()
        self.radius = entity.radius
        self.entities = entities
        self.create()

    def initialData(self):
        return {'radius':self.radius}

    def updateState(self):
        if self.id not in BigWorld.entities.keys():
            self.entities.remove(self)
            return

        points = tuple(map(tuple, self.entity.points))
        if self.points != points:
            self.points = points
            return True

    def state(self):
        return self.points

class Shot(Entity):
    name = 'shot'

    def __init__(self, shot, server, entities):
        Entity.__init__(self, server)

        timeCoefficient = 10.0/27.6369247437

        self.shot = shot
        self.id = shot.shotID
        self.origin = tuple(shot._position)
        self.target = tuple(shot.targetPos)
        self.entities = entities
        self.time = shot._serverTimeLeft * timeCoefficient
        self.distance = shot._hitDistance
        self.dir = tuple(shot._direction)

        self.create()

    def initialData(self):
        return {
            'origin': self.origin,
            'target': self.target,
            'type': self.shot.params.ammoType, #AP/HE
            'time': self.time,
            'distance': self.distance,
            'dir': self.dir,
        }

    def updateState(self):   
        if not self.shot._live:
            self.entities.remove(self)

    def state(self):
        pass

class Torpedo(Entity):
    name = 'torpedo'
    
    def __init__(self, torpedo, server, entities):
        Entity.__init__(self, server)
        self.entities = entities

        self.torpedo = torpedo
        self.speed = torpedo._speed
        self.direction = tuple(torpedo._direction)
        self.id = torpedo.shotID

        self.create()

    def initialData(self):
        return {
            'position': tuple(self.torpedo._position),
            'speed': self.speed,
            'direction': self.direction,
            'position': tuple(self.torpedo._position),
        }

    def updateState(self):
        if not self.torpedo._live:
            self.entities.remove(self)
        #else:
        #    return True

    def state(self):
        return tuple(self.torpedo._position) #only for debug purposes

tracked = {
    'SmokeScreen': SmokeScreen
}

class Entities:
    def __init__(self, server):
        self.server = server
        self.entities = {}

    def update(self):
        self.checkEntities()
        for entity in self.entities.values():
            entity.update()

    def informClient(self, client):
        for entity in self.entities.values():
            entity.informClient(client)

    def remove(self, entity):
        del self.entities[entity.id]
        entity.remove()

    def checkEntities(self):
        for id, entity in BigWorld.entities.items():
            cls = tracked.get(entity.__class__.__name__)
            if cls:
                if id not in self.entities:
                    instance = cls(id, entity, self.server, self)
                    self.entities[id] = instance

    def createShot(self, shot):
        instance = Shot(shot, self.server, self)
        self.entities[instance.id] = instance

    def createTorpedo(self, torp):
        try:
            instance = Torpedo(torp, self.server, self)
            self.entities[instance.id] = instance
        except:
            mapi.log_exc()

    def startMatch(self):
        __import__(BigWorld.player().shotsManager.__module__).gNewShotCreated.add(self.createShot)
        __import__(BigWorld.player().shotsManager.__module__).gNewTorpedoCreated.add(self.createTorpedo)