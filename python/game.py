import BWPersonality, Junk, BigWorld, json, time, math

Entities = mapi.require('entities').Entities

def getPlayers():
    return BWPersonality.PlayersInfo.__playerInfos

def translateShipName(name):
    id = 'IDS_' + name.split('_')[0]
    return mapi.trans.gettext(id)

class Player:
    def __init__(self, id, obj, ownTeam):
        self.id = id
        self.name = obj.name
        self.obj = obj
        self.spottedOnce = False

        if obj.isOwn:
            self.me = BigWorld.player()
        else:
            self.me = False

        if ownTeam:
            self.team = 'ally'
        else:
            self.team = 'enemy'

        # self.obj.isAlive
        # self.obj.shipGameData.isVisible

    def info(self):
        gd = self.obj.shipGameData
        si = self.obj.shipInfo
        return {
            'id': self.id,
            'avatarId': self.obj.avatarId,
            'name': self.name,
            #'team': self.obj.teamId,
            'team': self.team,
            'self': self.obj.isOwn,
            'ship': {
                'name': mapi.trans.gettext(si.nameIDS),
                'short': mapi.trans.gettext(si.nameIDS + '_SHORT'),
                'maxHealth': si.maxHealth,
                'type': si.subtype,
                'id': self.obj.shipId,
            }
        }

    def state(self):
        gd = self.obj.shipGameData

        if gd.isMiniMapVisible:
            self.spottedOnce = True

        if self.spottedOnce:
            spotted = gd.isMiniMapVisible
        else:
            spotted = None

        if hasattr(gd, 'velocity'):
            x,y,z = gd.velocity
            speed = math.sqrt(x*x + y*y + z*z) * 11.158506041729634 # in knots
        else:
            speed = 0.0

        result = {
            'id': self.id,
            'position': tuple(gd.position), # x(-west,+east),y,z(+north,-south), position | positionFromServer
            #'speed': getattr(gd, 'speed', 0.0) * 0.3826053718049, # in knots
            'speed': speed,
            'dir': gd.yaw, #in radians with 0 north, yaw | yawFromServer
            'health': gd.health,
            'alive': self.obj.isAlive,
            'spotted': spotted,
            'visible': gd.isVisible,
        }

        if self.me:
            weapon = result['weapon'] = self.me.selectedWeapon
            result['targeting'] = self.me.targeting.getTargetId(weapon)

        return result

class Game:
    def __init__(self, server):
        self.server = server
        self.inMatch = False
        self.players = []
        self.entities = Entities(server)

    def send(self, **data):
        self.server.send_message_to_all(json.dumps(data))

    def startMatch(self):
        self.inMatch = True

        for player in getPlayers().values():
            if player.isOwn:
                ownTeam = player.teamId

        self.players = [Player(id, player, ownTeam == player.teamId) for id, player in getPlayers().items()]
        self.send(type='info', data=self.info())

    def endMatch(self):
        self.inMatch = False
        self.players = []
        self.send(type='info', data=self.info())

    def update(self):
        self.entities.update()
        players = getPlayers()
        if len(players) > 0 and not self.inMatch:
            self.startMatch()
        elif len(players) == 0 and self.inMatch:
            self.endMatch()

        if self.inMatch:
            self.send(type='update', data=self.matchState())

    def mapInfo(self):
        if self.inMatch:
            spaceID = BigWorld.player().spaceID
            high, low = Junk.getMapBorder(spaceID)
            return {
                'border': {
                    'high': tuple(high),
                    'low': tuple(low),
                }
            }

    def info(self):
        return {
            'inMatch': self.inMatch,
            'map': self.mapInfo(),
            'players': [player.info() for player in self.players],
        }

    def matchState(self):
        return [player.state() for player in self.players]

    def informClient(self, client):
        try:
            self.server.send_message(client, json.dumps({'type':'info', 'data':self.info()}))
            self.entities.informClient(client)
        except:
            mapi.log_exc()