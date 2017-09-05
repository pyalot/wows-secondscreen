'''
BWPersonality.PlayersInfo.__playerInfos -> dict of players

player
    'accountDBID',
    'avatarId',
    'clanTag', 
    'crewParams', 
    'fragsCount', 
    'hTTKStatus', 
    'id', 
    'invitationsEnabled', 
    'isAbuser', -> pink? 
    'isAlive', 
    'isBot', 
    'isClientLoaded', 
    'isConnected', 
    'isHidden', 
    'isInvisible', 
    'isLeaver', 
    'isOwn', 
    'isPreBattleOwner', 
    'killedBuildingsCount', 
    'maxHealth', 
    'name', 
    'onTeammateMadeTeamDamage', 
    'preBattleIdOnStart', 
    'preBattleSign', 
    'prebattleId', 
    'prebattleIndex', 
    'rankInfoDump', 
    'setShipVisible', 
    'shipComponents', 
    'shipConfig', 
    'shipGameData', 
    'shipId', 
    'shipInfo', 
    'shipParamsId', 
    'teamId', 
    'teammateDamages', 
    'ttkStatus', 
    'vehicleParams'

player.shipGameData ->
    'buoyancy', ??? 
    'health', 
    'height', ???
    'isMiniMapVisible', 
    'isShipVisible', 
    'isVisible', 
    'maxHealth', ???
    'position' -> x(-west,+east),y,z(+north,-south)
    'regenerationHealth', ???
    'speed' -> speed in unknown unit, 57.5004995257 -> 22 knots, 13.9994999767 -> 5.4 knots, conversion factor = *0.38260537180493609354842460796024 to knots
    'speedServerLerper' ???
    'velocity', vec2 of velocity
    'yaw' -> in radians with 0 north

    112.000499524 speed

    0.0295104980469, 3.86241149902 velocity -> 

    |velocity| * 11.158506041729634 -> knots

    43.1 kts (formally 43)


'''

import BWPersonality, Junk, BigWorld, json, time, math

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
        except:
            mapi.log_exc()