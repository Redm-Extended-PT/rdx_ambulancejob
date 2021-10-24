fx_version "adamant"

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

games {"rdr3"}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@rdx_core/locale.lua',
	'locales/pt.lua',
	'locales/en.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@rdx_core/locale.lua',
	'locales/pt.lua',
	'locales/en.lua',
	'config.lua',
	'client/main.lua',
	'client/job.lua'
}

dependency 'rdx_core'
