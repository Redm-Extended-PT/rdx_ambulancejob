Config                            = {}

Config.ReviveReward               = 5  -- revive reward, set to 0 if you don't want it enabled
Config.AntiCombatLog              = true -- enable anti-combat logging?
Config.Locale = 'pt'
Config.RespawnTime = 30000

local second = 1000
local minute = 60 * second

Config.ShowDeathTimer = true --dont tuch
Config.EarlyRespawnTimer          = 1 * minute  -- Time til respawn is available 7
Config.BleedoutTimer              = 1 * minute -- Time til the player bleeds out 5
Config.EnableArmoryManagement 		= true
Config.EnablePlayerManagement       = true
Config.RemoveWeaponsAfterRPDeath    = true
Config.RemoveCashAfterRPDeath       = true
Config.RemoveItemsAfterRPDeath      = true
Config.EarlyRespawn                 = true
Config.EarlyRespawnFine                  = true
Config.EarlyRespawnFineAmount            = 50

Config.RespawnPoint = {coords = vector3(-282.67, 815.17, 119.04), heading = 354.17}

Config.Zones = {

	AmbulanceActions = { -- Cloakroom
		Pos	= { x = -288.46, y = 808.86, z = 119.44 },
		Type = 23
	},

	Pharmacy = {
		Pos	= { x = -290.72, y = 815.37, z = 119.44 },
		Type = 23
	}
}
