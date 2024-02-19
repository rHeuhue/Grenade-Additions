/*
_____/\\\\\\\\\_____/\\\\____________/\\\\__/\\\_______/\\\__/\\\_______/\\\________________/\\\\\\\\\\\\\_______/\\\\\\\\\\\\_        
 ___/\\\\\\\\\\\\\__\/\\\\\\________/\\\\\\_\///\\\___/\\\/__\///\\\___/\\\/________________\/\\\/////////\\\___/\\\//////////__       
  __/\\\/////////\\\_\/\\\//\\\____/\\\//\\\___\///\\\\\\/______\///\\\\\\/__________________\/\\\_______\/\\\__/\\\_____________      
   _\/\\\_______\/\\\_\/\\\\///\\\/\\\/_\/\\\_____\//\\\\__________\//\\\\_______/\\\\\\\\\\\_\/\\\\\\\\\\\\\\__\/\\\____/\\\\\\\_     
    _\/\\\\\\\\\\\\\\\_\/\\\__\///\\\/___\/\\\______\/\\\\___________\/\\\\______\///////////__\/\\\/////////\\\_\/\\\___\/////\\\_    
     _\/\\\/////////\\\_\/\\\____\///_____\/\\\______/\\\\\\__________/\\\\\\___________________\/\\\_______\/\\\_\/\\\_______\/\\\_   
      _\/\\\_______\/\\\_\/\\\_____________\/\\\____/\\\////\\\______/\\\////\\\_________________\/\\\_______\/\\\_\/\\\_______\/\\\_  
       _\/\\\_______\/\\\_\/\\\_____________\/\\\__/\\\/___\///\\\__/\\\/___\///\\\_______________\/\\\\\\\\\\\\\/__\//\\\\\\\\\\\\/__ 
        _\///________\///__\///______________\///__\///_______\///__\///_______\///________________\/////////////_____\////////////____
					__/\\\________/\\\_______________________________/\\\______________________________________                                            
					 _\/\\\_______\/\\\______________________________\/\\\______________________________________                                           
					  _\/\\\_______\/\\\______________________________\/\\\______________________________________                                          
					   _\/\\\\\\\\\\\\\\\__/\\\____/\\\_____/\\\\\\\\__\/\\\__________/\\\____/\\\_____/\\\\\\\\__                                         
					    _\/\\\/////////\\\_\/\\\___\/\\\___/\\\/////\\\_\/\\\\\\\\\\__\/\\\___\/\\\___/\\\/////\\\_                                        
					     _\/\\\_______\/\\\_\/\\\___\/\\\__/\\\\\\\\\\\__\/\\\/////\\\_\/\\\___\/\\\__/\\\\\\\\\\\__                                       
					      _\/\\\_______\/\\\_\/\\\___\/\\\_\//\\///////___\/\\\___\/\\\_\/\\\___\/\\\_\//\\///////___                                      
					       _\/\\\_______\/\\\_\//\\\\\\\\\___\//\\\\\\\\\\_\/\\\___\/\\\_\//\\\\\\\\\___\//\\\\\\\\\\_                                     
					        _\///________\///___\/////////_____\//////////__\///____\///___\/////////_____\//////////__
*/


#include <amxmodx>
#include <reapi_stocks>

#define CC_COLORS_TYPE CC_COLORS_SHORT
#include <cromchat>

#define VERSION "1.0.11"

new const TRAILBEAM_SPR[] = "sprites/arrow1.spr"
new g_iSprTrailBeam

const MAX_COLORS_LENGTH = 64
const MAX_CHAT_MESSAGE_LENGTH = 128

enum _:eCvarSettings
{
	CHAT_MESSAGE,
	CHAT_MESSAGES_TEAM_OR_NOT,
	TRAIL_FOLLOW,
	NADE_GLOW,
	HE_GRENADE_COLORS[MAX_COLORS_LENGTH],
	FLASH_BANG_COLORS[MAX_COLORS_LENGTH],
	SMOKE_GRENADE_COLORS[MAX_COLORS_LENGTH],

	HE_TRAIL_LIFE, HE_TRAIL_WIDTH,
	FLASH_TRAIL_LIFE, FLASH_TRAIL_WIDTH,
	SMOKE_TRAIL_LIFE, SMOKE_TRAIL_WIDTH,

	CHAT_MESSAGE_HE[MAX_CHAT_MESSAGE_LENGTH],
	CHAT_MESSAGE_FLASH[MAX_CHAT_MESSAGE_LENGTH],
	CHAT_MESSAGE_SMOKE[MAX_CHAT_MESSAGE_LENGTH]
}

new g_eGrenadeAdditions[eCvarSettings]

enum eType
{
	HE_GRENADE, FLASH_BANG, SMOKE_GRENADE
}
enum _:eRGBA
{
	R, G, B, A
}
new g_eRGBA[eType][eRGBA]

new const g_szSound[] = "radio/ct_fireinhole.wav"

public plugin_init()
{
	register_plugin("Grenade Additions", VERSION, "Huehue @ AMXX-BG.INFO")
	
	RegisterHookChain(RG_ThrowHeGrenade, "ThrowHeGrenade", true)
	RegisterHookChain(RG_ThrowFlashbang, "ThrowFlashbang", true)
	RegisterHookChain(RG_ThrowSmokeGrenade, "ThrowSmokeGrenade", true)

	RegisterHookChain(RG_CBasePlayer_Radio, "CBasePlayer_Radio_Pre", false)

	new pCvar

	// Basic settings to enable/disable
	pCvar = create_cvar("ga_chat_message", "1", FCVAR_NONE, "Enable/Disable the message in chat for what type nade is thrown", true, 0.0, true, 1.0)
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[CHAT_MESSAGE])

	pCvar = create_cvar("ga_chat_team_message", "1", FCVAR_NONE, "Enable/Disable the message whether to be for team only or not", true, 0.0, true, 1.0)
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[CHAT_MESSAGES_TEAM_OR_NOT])

	pCvar = create_cvar("ga_trail_follow", "1", FCVAR_NONE, "Enable/Disable the trail following the grenade after throw", true, 0.0, true, 1.0)
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[TRAIL_FOLLOW])

	pCvar = create_cvar("ga_nade_glow", "1", FCVAR_NONE, "Enable/Disable the nade glowing after throw", true, 0.0, true, 1.0)
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[NADE_GLOW])

	// Settings for HE Grenade
	pCvar = create_cvar("ga_he_nade_colors", "255 0 0 100", FCVAR_NONE, "HE Grenade Colors RGBA [Red, Green, Blue, Brightness(Alpha)]^nFor Random colors type in: random", true, 0.0, true, 255.0)
	bind_pcvar_string(pCvar, g_eGrenadeAdditions[HE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[HE_GRENADE_COLORS]))

	pCvar = create_cvar("ga_he_trail_life", "10", FCVAR_NONE, "He Grenade Trail life")
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[HE_TRAIL_LIFE])

	pCvar = create_cvar("ga_he_trail_width", "10", FCVAR_NONE, "He Grenade Width")
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[HE_TRAIL_WIDTH])

	pCvar = create_cvar("ga_he_chat_message", "!n>> !g<name> !n: !rGrenade", FCVAR_NONE, "The chat message that will appear when He Grenade is thrown")
	bind_pcvar_string(pCvar, g_eGrenadeAdditions[CHAT_MESSAGE_HE], charsmax(g_eGrenadeAdditions[CHAT_MESSAGE_HE]))

	// Settings for Flash Bang
	pCvar = create_cvar("ga_flash_bang_colors", "255 255 255 100", FCVAR_NONE, "Flash Bang Colors RGBA [Red, Green, Blue, Brightness(Alpha)]^nFor Random colors type in: random", true, 0.0, true, 255.0)
	bind_pcvar_string(pCvar, g_eGrenadeAdditions[FLASH_BANG_COLORS], charsmax(g_eGrenadeAdditions[FLASH_BANG_COLORS]))

	pCvar = create_cvar("ga_flashbang_trail_life", "10", FCVAR_NONE, "Flash Bang Trail life")
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[FLASH_TRAIL_LIFE])

	pCvar = create_cvar("ga_flashbang_trail_width", "10", FCVAR_NONE, "Flash Bang Width")
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[FLASH_TRAIL_WIDTH])

	pCvar = create_cvar("ga_flash_chat_message", "!n>> !g<name> !n: !wFlash", FCVAR_NONE, "The chat message that will appear when Flashbang is thrown")
	bind_pcvar_string(pCvar, g_eGrenadeAdditions[CHAT_MESSAGE_FLASH], charsmax(g_eGrenadeAdditions[CHAT_MESSAGE_FLASH]))

	// Settings for Smoke Grenade
	pCvar = create_cvar("ga_smoke_nade_colors", "0 255 0 100", FCVAR_NONE, "Smoke Grenade Colors RGBA [Red, Green, Blue, Brightness(Alpha)]^nFor Random colors type in: random", true, 0.0, true, 255.0)
	bind_pcvar_string(pCvar, g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS]))

	pCvar = create_cvar("ga_smoke_trail_life", "10", FCVAR_NONE, "Smoke Grenade Trail life")
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[SMOKE_TRAIL_LIFE])

	pCvar = create_cvar("ga_smoke_trail_width", "10", FCVAR_NONE, "Smoke Grenade Width")
	bind_pcvar_num(pCvar, g_eGrenadeAdditions[SMOKE_TRAIL_WIDTH])

	pCvar = create_cvar("ga_smoke_chat_message", "!n>> !t<name> !n: !gSmoke", FCVAR_NONE, "The chat message that will appear when Smoke Grenade is thrown")
	bind_pcvar_string(pCvar, g_eGrenadeAdditions[CHAT_MESSAGE_SMOKE], charsmax(g_eGrenadeAdditions[CHAT_MESSAGE_SMOKE]))

	// Auto Config Create & Load
	AutoExecConfig(true, "Grenade_Additions", "HuehuePlugins_Config")

	register_message(get_user_msgid("SendAudio"), "MessageSendAudio")
}

public OnConfigsExecuted()
{
	replace_all(g_eGrenadeAdditions[CHAT_MESSAGE_HE], charsmax(g_eGrenadeAdditions[CHAT_MESSAGE_HE]), "<name>", "%n")
	replace_all(g_eGrenadeAdditions[CHAT_MESSAGE_FLASH], charsmax(g_eGrenadeAdditions[CHAT_MESSAGE_FLASH]), "<name>", "%n")
	replace_all(g_eGrenadeAdditions[CHAT_MESSAGE_SMOKE], charsmax(g_eGrenadeAdditions[CHAT_MESSAGE_SMOKE]), "<name>", "%n")

	GenerateNewColors()
}

public plugin_precache()
{
	g_iSprTrailBeam = precache_model(TRAILBEAM_SPR)
	precache_sound(g_szSound)
}

public CBasePlayer_Radio_Pre(const iPlayer, const szMessageId[], const szMessageVerbose[], iPitch, bool:bShowIcon)
{
	#pragma unused iPlayer, szMessageId, iPitch, bShowIcon
	
	if (szMessageVerbose[0] == EOS)
		return HC_CONTINUE;
	
	if (szMessageVerbose[3] == 'r')
		return HC_SUPERCEDE;
	
	return HC_CONTINUE;
}

public ThrowHeGrenade(const id, Float:vecStart[3], Float:vecVelocity[3], Float:time, const team, const usEvent)
{
	new iEntity = GetHookChainReturn(ATYPE_INTEGER);

	if (is_nullent(iEntity))
		return

	if (equal(g_eGrenadeAdditions[HE_GRENADE_COLORS], "random"))
		GenerateNewColors()

	if (g_eGrenadeAdditions[NADE_GLOW])
	{
		static Float:flColors[3]
		flColors[0] = float(g_eRGBA[HE_GRENADE][R])
		flColors[1] = float(g_eRGBA[HE_GRENADE][G])
		flColors[2] = float(g_eRGBA[HE_GRENADE][B])
		rg_set_entity_rendering(iEntity, kRenderFxGlowShell, flColors, kRenderNormal, 16.0)
	}

	if (g_eGrenadeAdditions[TRAIL_FOLLOW])
		UTIL_CreateTrail(iEntity, g_eGrenadeAdditions[HE_TRAIL_LIFE], g_eGrenadeAdditions[HE_TRAIL_WIDTH], g_eRGBA[HE_GRENADE][R], g_eRGBA[HE_GRENADE][G], g_eRGBA[HE_GRENADE][B], g_eRGBA[HE_GRENADE][A])

	if (g_eGrenadeAdditions[CHAT_MESSAGE] && g_eGrenadeAdditions[CHAT_MESSAGE_HE] != EOS)
	{
		if (g_eGrenadeAdditions[CHAT_MESSAGES_TEAM_OR_NOT])
		{
			new iPlayers[MAX_PLAYERS], iNum, iPlayer
			get_players(iPlayers, iNum)
			
			for (--iNum; iNum >= 0; iNum--)
			{
				iPlayer = iPlayers[iNum]

				if (rg_get_user_team(id) == rg_get_user_team(iPlayer))
					CC_SendMatched(0, id, g_eGrenadeAdditions[CHAT_MESSAGE_HE], id)
			}
		}
		else
			CC_SendMatched(0, id, g_eGrenadeAdditions[CHAT_MESSAGE_HE], id)
	}

	emit_sound(id, CHAN_VOICE, g_szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public ThrowFlashbang(const id, Float:vecStart[3], Float:vecVelocity[3], Float:time)
{
	new iEntity = GetHookChainReturn(ATYPE_INTEGER);

	if (is_nullent(iEntity))
		return

	if (equal(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], "random"))
		GenerateNewColors()

	if (g_eGrenadeAdditions[NADE_GLOW])
	{
		static Float:flColors[3]
		flColors[0] = float(g_eRGBA[FLASH_BANG][R])
		flColors[1] = float(g_eRGBA[FLASH_BANG][G])
		flColors[2] = float(g_eRGBA[FLASH_BANG][B])
		rg_set_entity_rendering(iEntity, kRenderFxGlowShell, flColors, kRenderNormal, 16.0)
	}

	if (g_eGrenadeAdditions[TRAIL_FOLLOW])
		UTIL_CreateTrail(iEntity, g_eGrenadeAdditions[FLASH_TRAIL_LIFE], g_eGrenadeAdditions[FLASH_TRAIL_WIDTH], g_eRGBA[FLASH_BANG][R], g_eRGBA[FLASH_BANG][G], g_eRGBA[FLASH_BANG][B], g_eRGBA[FLASH_BANG][A])
	
	if (g_eGrenadeAdditions[CHAT_MESSAGE] && g_eGrenadeAdditions[CHAT_MESSAGE_FLASH] != EOS)
	{
		if (g_eGrenadeAdditions[CHAT_MESSAGES_TEAM_OR_NOT])
		{
			new iPlayers[MAX_PLAYERS], iNum, iPlayer
			get_players(iPlayers, iNum)
			
			for (--iNum; iNum >= 0; iNum--)
			{
				iPlayer = iPlayers[iNum]

				if (rg_get_user_team(id) == rg_get_user_team(iPlayer))
					CC_SendMatched(0, id, g_eGrenadeAdditions[CHAT_MESSAGE_FLASH], id)
			}
		}
		else
			CC_SendMatched(0, id, g_eGrenadeAdditions[CHAT_MESSAGE_FLASH], id)
	}

	emit_sound(id, CHAN_VOICE, g_szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public ThrowSmokeGrenade(const id, Float:vecStart[3], Float:vecVelocity[3], Float:time, const usEvent)
{
	new iEntity = GetHookChainReturn(ATYPE_INTEGER);

	if (is_nullent(iEntity))
		return

	if (equal(g_eGrenadeAdditions[FLASH_BANG_COLORS], "random"))
		GenerateNewColors()

	if (g_eGrenadeAdditions[NADE_GLOW])
	{
		static Float:flColors[3]
		flColors[0] = float(g_eRGBA[SMOKE_GRENADE][R])
		flColors[1] = float(g_eRGBA[SMOKE_GRENADE][G])
		flColors[2] = float(g_eRGBA[SMOKE_GRENADE][B])
		rg_set_entity_rendering(iEntity, kRenderFxGlowShell, flColors, kRenderNormal, 16.0)
	}

	if (g_eGrenadeAdditions[TRAIL_FOLLOW])
		UTIL_CreateTrail(iEntity, g_eGrenadeAdditions[SMOKE_TRAIL_LIFE], g_eGrenadeAdditions[SMOKE_TRAIL_WIDTH], g_eRGBA[SMOKE_GRENADE][R], g_eRGBA[SMOKE_GRENADE][G], g_eRGBA[SMOKE_GRENADE][B], g_eRGBA[SMOKE_GRENADE][A])

	if (g_eGrenadeAdditions[CHAT_MESSAGE] && g_eGrenadeAdditions[CHAT_MESSAGE_SMOKE] != EOS)
	{
		if (g_eGrenadeAdditions[CHAT_MESSAGES_TEAM_OR_NOT])
		{
			new iPlayers[MAX_PLAYERS], iNum, iPlayer
			get_players(iPlayers, iNum)
			
			for (--iNum; iNum >= 0; iNum--)
			{
				iPlayer = iPlayers[iNum]

				if (rg_get_user_team(id) == rg_get_user_team(iPlayer))
					CC_SendMatched(0, id, g_eGrenadeAdditions[CHAT_MESSAGE_SMOKE], id)
			}
		}
		else
			CC_SendMatched(0, id, g_eGrenadeAdditions[CHAT_MESSAGE_SMOKE], id)
	}

	emit_sound(id, CHAN_VOICE, g_szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public MessageSendAudio() // Тут блокируем стандартный звук
{
	if(EqualValue( 2, "%!MRAD_FIREINHOLE" ))
	{
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

EqualValue( const iParam, const szString[ ] ) 
{
	new szTemp[ 18 ];
	get_msg_arg_string( iParam, szTemp, 17 );

	return ( equal( szTemp, szString ) ) ? 1 : 0;
}

UTIL_CreateTrail(iEntity, iLife = 10, iWidth = 10, iRed, iGreen, iBlue, iBrightness = 100)
{
	UTIL_DestroyTrail(iEntity)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)		// TE_*
	write_short(iEntity) 			// entity
	write_short(g_iSprTrailBeam) 	// sprite
	write_byte(iLife) 				// life
	write_byte(iWidth) 				// width
	write_byte(iRed) 				// red
	write_byte(iGreen) 				// green
	write_byte(iBlue) 				// blue
	write_byte(iBrightness) 		// brightness
	message_end()
}

UTIL_DestroyTrail(iEntity)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)			// TE_*
	write_short(iEntity) 			// entity
	message_end()
}

GenerateNewColors()
{
	static szPlace[6]

	if (equal(g_eGrenadeAdditions[HE_GRENADE_COLORS], "random"))
	{
		g_eRGBA[HE_GRENADE][R] = random(256)
		g_eRGBA[HE_GRENADE][G] = random(256)
		g_eRGBA[HE_GRENADE][B] = random(256)
		g_eRGBA[HE_GRENADE][A] = random(256)
	}
	else
	{
		argbreak(g_eGrenadeAdditions[HE_GRENADE_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[HE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[HE_GRENADE_COLORS]))
		g_eRGBA[HE_GRENADE][R] = str_to_num(szPlace)
		argbreak(g_eGrenadeAdditions[HE_GRENADE_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[HE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[HE_GRENADE_COLORS]))
		g_eRGBA[HE_GRENADE][G] = str_to_num(szPlace)
		argbreak(g_eGrenadeAdditions[HE_GRENADE_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[HE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[HE_GRENADE_COLORS]))
		g_eRGBA[HE_GRENADE][B] = str_to_num(szPlace)
		g_eRGBA[HE_GRENADE][A] = str_to_num(g_eGrenadeAdditions[HE_GRENADE_COLORS])
	}

	if (equal(g_eGrenadeAdditions[FLASH_BANG_COLORS], "random"))
	{
		g_eRGBA[FLASH_BANG][R] = random(256)
		g_eRGBA[FLASH_BANG][G] = random(256)
		g_eRGBA[FLASH_BANG][B] = random(256)
		g_eRGBA[FLASH_BANG][A] = random(256)
	}
	else
	{
		argbreak(g_eGrenadeAdditions[FLASH_BANG_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[FLASH_BANG_COLORS], charsmax(g_eGrenadeAdditions[FLASH_BANG_COLORS]))
		g_eRGBA[FLASH_BANG][R] = str_to_num(szPlace)
		argbreak(g_eGrenadeAdditions[FLASH_BANG_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[FLASH_BANG_COLORS], charsmax(g_eGrenadeAdditions[FLASH_BANG_COLORS]))
		g_eRGBA[FLASH_BANG][G] = str_to_num(szPlace)
		argbreak(g_eGrenadeAdditions[FLASH_BANG_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[FLASH_BANG_COLORS], charsmax(g_eGrenadeAdditions[FLASH_BANG_COLORS]))
		g_eRGBA[FLASH_BANG][B] = str_to_num(szPlace)
		g_eRGBA[FLASH_BANG][A] = str_to_num(g_eGrenadeAdditions[FLASH_BANG_COLORS])
	}

	if (equal(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], "random"))
	{
		g_eRGBA[SMOKE_GRENADE][R] = random(256)
		g_eRGBA[SMOKE_GRENADE][G] = random(256)
		g_eRGBA[SMOKE_GRENADE][B] = random(256)
		g_eRGBA[SMOKE_GRENADE][A] = random(256)
	}
	else
	{
		argbreak(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS]))
		g_eRGBA[SMOKE_GRENADE][R] = str_to_num(szPlace)
		argbreak(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS]))
		g_eRGBA[SMOKE_GRENADE][G] = str_to_num(szPlace)
		argbreak(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], szPlace, charsmax(szPlace), g_eGrenadeAdditions[SMOKE_GRENADE_COLORS], charsmax(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS]))
		g_eRGBA[SMOKE_GRENADE][B] = str_to_num(szPlace)
		g_eRGBA[SMOKE_GRENADE][A] = str_to_num(g_eGrenadeAdditions[SMOKE_GRENADE_COLORS])
	}
}
/*
stock rg_set_entity_rendering(const entity, fx = kRenderFxNone, Float:color[] = {255.0, 255.0, 255.0}, render = kRenderNormal, Float:amount = 16.0) 
{
	set_entvar(entity, var_renderfx, fx)
	set_entvar(entity, var_rendercolor, color)
	set_entvar(entity, var_rendermode, render)
	set_entvar(entity, var_renderamt, amount)
}*/