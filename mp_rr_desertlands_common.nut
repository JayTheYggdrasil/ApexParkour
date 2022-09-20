global function Desertlands_PreMapInit_Common
global function Desertlands_MapInit_Common
global function CodeCallback_PlayerEnterUpdraftTrigger
global function CodeCallback_PlayerLeaveUpdraftTrigger

#if SERVER
global function Desertlands_MU1_MapInit_Common
global function Desertlands_MU1_EntitiesLoaded_Common
global function Desertlands_MU1_UpdraftInit_Common
global function Desertlands_SetTrainEnabled
#endif


#if SERVER
//Copied from _jump_pads. This is being hacked for the geysers.
const float JUMP_PAD_PUSH_RADIUS = 256.0
const float JUMP_PAD_PUSH_PROJECTILE_RADIUS = 32.0//98.0
const float JUMP_PAD_PUSH_VELOCITY = 2000.0
const float JUMP_PAD_VIEW_PUNCH_SOFT = 25.0
const float JUMP_PAD_VIEW_PUNCH_HARD = 4.0
const float JUMP_PAD_VIEW_PUNCH_RAND = 4.0
const float JUMP_PAD_VIEW_PUNCH_SOFT_TITAN = 120.0
const float JUMP_PAD_VIEW_PUNCH_HARD_TITAN = 20.0
const float JUMP_PAD_VIEW_PUNCH_RAND_TITAN = 20.0
const TEAM_JUMPJET_DBL = $"P_team_jump_jet_ON_trails"
const ENEMY_JUMPJET_DBL = $"P_enemy_jump_jet_ON_trails"
const asset JUMP_PAD_MODEL = $"mdl/props/octane_jump_pad/octane_jump_pad.rmdl"

const float JUMP_PAD_ANGLE_LIMIT = 0.70
const float JUMP_PAD_ICON_HEIGHT_OFFSET = 48.0
const float JUMP_PAD_ACTIVATION_TIME = 0.5
const asset JUMP_PAD_LAUNCH_FX = $"P_grndpnd_launch"
const JUMP_PAD_DESTRUCTION = "jump_pad_destruction"

// Loot drones
const int NUM_LOOT_DRONES_TO_SPAWN = 12
const int NUM_LOOT_DRONES_WITH_VAULT_KEYS = 4
#endif

struct
{
	#if SERVER
	bool isTrainEnabled = true
	#endif

	vector auto_tp = <5486, 9155, -627>

    table<entity, int> cp_table = {}

	int current_cp = 0
	array<vector> cps_pos = [<6893, 1086, -1385>, <4839, 1146, -1193>, <3389, 1982, -937>, <3389, 3681, -617>, <3394, 6570, -1257>, <4606, 9088, -745>, <5881, 8712, 4822>]
	array<vector> cps_ang = [<-89,-178,-0>, <-0,-178,-0>, <-0, 89, -0>, <3, 51, -0>, <0, 90, -0>, <3, -0, -0>, <21, -46, -0>]
} file

void function Desertlands_PreMapInit_Common()
{
	//DesertlandsTrain_PreMapInit()
}

void function Desertlands_MapInit_Common()
{
	printt( "Desertlands_MapInit_Common" )

	MapZones_RegisterDataTable( $"datatable/map_zones/zones_mp_rr_desertlands_64k_x_64k.rpak" )

	FlagInit( "PlayConveyerStartFX", true )

	SetVictorySequencePlatformModel( $"mdl/rocks/desertlands_victory_platform.rmdl", < 0, 0, -10 >, < 0, 0, 0 > )

	#if SERVER
		//%if HAS_LOOT_DRONES && HAS_LOOT_ROLLERS
		InitLootDrones()
		InitLootRollers()
		//%endif

		AddCallback_EntitiesDidLoad( EntitiesDidLoad )

		SURVIVAL_SetPlaneHeight( 15250 )
		SURVIVAL_SetAirburstHeight( 2500 )
		SURVIVAL_SetMapCenter( <0, 0, 0> )
		//Survival_SetMapFloorZ( -8000 )

		//if ( file.isTrainEnabled )
		//	DesertlandsTrain_Precaches()

		AddSpawnCallback_ScriptName( "desertlands_train_mover_0", AddTrainToMinimap )

		SpawnEditorProps()
	#endif

	#if CLIENT
		Freefall_SetPlaneHeight( 15250 )
		Freefall_SetDisplaySeaHeightForLevel( -8961.0 )

		SetVictorySequenceLocation( <11092.6162, -20878.0684, 1561.52222>, <0, 267.894653, 0> )
		SetVictorySequenceSunSkyIntensity( 1.0, 0.5 )
		SetMinimapBackgroundTileImage( $"overviews/mp_rr_canyonlands_bg" )

		// RegisterMinimapPackage( "prop_script", eMinimapObject_prop_script.TRAIN, MINIMAP_OBJECT_RUI, MinimapPackage_Train, FULLMAP_OBJECT_RUI, FullmapPackage_Train )
	#endif
}

#if SERVER
void function EntitiesDidLoad()
{
	#if SERVER && DEV
		test_runmapchecks()
	#endif

	GeyserInit()
	Updrafts_Init()

	InitLootDronePaths()

	string currentPlaylist = GetCurrentPlaylistName()
	// thread SpawnLootDrones( GetPlaylistVarInt( currentPlaylist, "loot_drones_spawn_count", NUM_LOOT_DRONES_TO_SPAWN ) )

	int keyCount = GetPlaylistVarInt( currentPlaylist, "loot_drones_vault_key_count", NUM_LOOT_DRONES_WITH_VAULT_KEYS )
	//if ( keyCount > 0 )
	//	LootRollers_ForceAddLootRefToRandomLootRollers( "data_knife", keyCount )

	if ( file.isTrainEnabled )
		thread DesertlandsTrain_Init()
}
#endif

#if SERVER
void function Desertlands_SetTrainEnabled( bool enabled )
{
	file.isTrainEnabled = enabled
}
#endif

//=================================================================================================
//=================================================================================================
//
//  ##     ## ##     ##    ##       ######   #######  ##     ## ##     ##  #######  ##    ##
//  ###   ### ##     ##  ####      ##    ## ##     ## ###   ### ###   ### ##     ## ###   ##
//  #### #### ##     ##    ##      ##       ##     ## #### #### #### #### ##     ## ####  ##
//  ## ### ## ##     ##    ##      ##       ##     ## ## ### ## ## ### ## ##     ## ## ## ##
//  ##     ## ##     ##    ##      ##       ##     ## ##     ## ##     ## ##     ## ##  ####
//  ##     ## ##     ##    ##      ##    ## ##     ## ##     ## ##     ## ##     ## ##   ###
//  ##     ##  #######   ######     ######   #######  ##     ## ##     ##  #######  ##    ##
//
//=================================================================================================
//=================================================================================================

#if SERVER
void function Desertlands_MU1_MapInit_Common()
{
	AddSpawnCallback_ScriptName( "conveyor_rotator_mover", OnSpawnConveyorRotatorMover )

	Desertlands_MapInit_Common()
	PrecacheParticleSystem( JUMP_PAD_LAUNCH_FX )

	//SURVIVAL_SetDefaultLootZone( "zone_medium" )

	//LaserMesh_Init()
	FlagSet( "DisableDropships" )

	AddDamageCallbackSourceID( eDamageSourceId.burn, OnBurnDamage )

	svGlobal.evacEnabled = false //Need to disable this on a map level if it doesn't support it at all
}


void function OnBurnDamage( entity player, var damageInfo )
{
	if ( !player.IsPlayer() )
		return

	// sky laser shouldn't hurt players in plane
	if ( player.GetPlayerNetBool( "playerInPlane" ) )
	{
		DamageInfo_SetDamage( damageInfo, 0 )
	}
}

///////////////////////
///////////////////////
//// Conveyor


void function OnSpawnConveyorRotatorMover( entity mover )
{
	thread ConveyorRotatorMoverThink( mover )
}


void function ConveyorRotatorMoverThink( entity mover )
{
	mover.EndSignal( "OnDestroy" )

	entity rotator = GetEntByScriptName( "conveyor_rotator" )
	entity startNode
	entity endNode

	array<entity> links = rotator.GetLinkEntArray()
	foreach ( l in links )
	{
		if ( l.GetValueForKey( "script_noteworthy" ) == "end" )
			endNode = l
		if ( l.GetValueForKey( "script_noteworthy" ) == "start" )
			startNode = l
	}


	float angle1 = VectorToAngles( startNode.GetOrigin() - rotator.GetOrigin() ).y
	float angle2 = VectorToAngles( endNode.GetOrigin() - rotator.GetOrigin() ).y

	float angleDiff = angle1 - angle2
	angleDiff = (angleDiff + 180) % 360 - 180

	float rotatorSpeed = float( rotator.GetValueForKey( "rotate_forever_speed" ) )
	float waitTime     = fabs( angleDiff ) / rotatorSpeed

	Assert( IsValid( endNode ) )

	while ( 1 )
	{
		mover.WaitSignal( "ReachedPathEnd" )

		mover.SetParent( rotator, "", true )

		wait waitTime

		mover.ClearParent()
		mover.SetOrigin( endNode.GetOrigin() )
		mover.SetAngles( endNode.GetAngles() )

		thread MoverThink( mover, [ endNode ] )
	}
}


void function Desertlands_MU1_UpdraftInit_Common( entity player )
{
	//ApplyUpdraftModUntilTouchingGround( player )
	thread PlayerSkydiveFromCurrentPosition( player )
	thread BurnPlayerOverTime( player )
}


void function Desertlands_MU1_EntitiesLoaded_Common()
{
	GeyserInit()
	Updrafts_Init()
}


//Geyster stuff
void function GeyserInit()
{
	array<entity> geyserTargets = GetEntArrayByScriptName( "geyser_jump" )
	foreach ( target in geyserTargets )
	{
		thread GeyersJumpTriggerArea( target )
		//target.Destroy()
	}
}


void function GeyersJumpTriggerArea( entity jumpPad )
{
	Assert ( IsNewThread(), "Must be threaded off" )
	jumpPad.EndSignal( "OnDestroy" )

	vector origin = OriginToGround( jumpPad.GetOrigin() )
	vector angles = jumpPad.GetAngles()

	entity trigger = CreateEntity( "trigger_cylinder_heavy" )
	SetTargetName( trigger, "geyser_trigger" )
	trigger.SetOwner( jumpPad )
	trigger.SetRadius( JUMP_PAD_PUSH_RADIUS )
	trigger.SetAboveHeight( 32 )
	trigger.SetBelowHeight( 16 ) //need this because the player or jump pad can sink into the ground a tiny bit and we check player feet not half height
	trigger.SetOrigin( origin )
	trigger.SetAngles( angles )
	trigger.SetTriggerType( TT_JUMP_PAD )
	trigger.SetLaunchScaleValues( JUMP_PAD_PUSH_VELOCITY, 1.25 )
	trigger.SetViewPunchValues( JUMP_PAD_VIEW_PUNCH_SOFT, JUMP_PAD_VIEW_PUNCH_HARD, JUMP_PAD_VIEW_PUNCH_RAND )
	trigger.SetLaunchDir( <0.0, 0.0, 1.0> )
	trigger.UsePointCollision()
	trigger.kv.triggerFilterNonCharacter = "0"
	DispatchSpawn( trigger )
	trigger.SetEnterCallback( Geyser_OnJumpPadAreaEnter )

	// entity traceBlocker = CreateTraceBlockerVolume( trigger.GetOrigin(), 24.0, true, CONTENTS_BLOCK_PING | CONTENTS_NOGRAPPLE, TEAM_MILITIA, GEYSER_PING_SCRIPT_NAME )
	// traceBlocker.SetBox( <-192, -192, -16>, <192, 192, 3000> )

	//DebugDrawCylinder( origin, < -90, 0, 0 >, JUMP_PAD_PUSH_RADIUS, trigger.GetAboveHeight(), 255, 0, 255, true, 9999.9 )
	//DebugDrawCylinder( origin, < -90, 0, 0 >, JUMP_PAD_PUSH_RADIUS, -trigger.GetBelowHeight(), 255, 0, 255, true, 9999.9 )

	OnThreadEnd(
		function() : ( trigger )
		{
			trigger.Destroy()
		} )

	WaitForever()
}


void function Geyser_OnJumpPadAreaEnter( entity trigger, entity ent )
{
	Geyser_JumpPadPushEnt( trigger, ent, trigger.GetOrigin(), trigger.GetAngles() )
}


void function Geyser_JumpPadPushEnt( entity trigger, entity ent, vector origin, vector angles )
{
	if ( Geyser_JumpPad_ShouldPushPlayerOrNPC( ent ) )
	{
		if ( ent.IsPlayer() )
		{
			entity jumpPad = trigger.GetOwner()
			if ( IsValid( jumpPad ) )
			{
				int fxId = GetParticleSystemIndex( JUMP_PAD_LAUNCH_FX )
				StartParticleEffectOnEntity( jumpPad, fxId, FX_PATTACH_ABSORIGIN_FOLLOW, 0 )
			}
			thread Geyser_JumpJetsWhileAirborne( ent )
		}
		else
		{
			EmitSoundOnEntity( ent, "JumpPad_LaunchPlayer_3p" )
			EmitSoundOnEntity( ent, "JumpPad_AirborneMvmt_3p" )
		}
	}
}


void function Geyser_JumpJetsWhileAirborne( entity player )
{
	if ( !IsPilot( player ) )
		return
	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.Signal( "JumpPadStart" )
	player.EndSignal( "JumpPadStart" )
	player.EnableSlowMo()
	player.DisableMantle()

	EmitSoundOnEntityExceptToPlayer( player, player, "JumpPad_LaunchPlayer_3p" )
	EmitSoundOnEntityExceptToPlayer( player, player, "JumpPad_AirborneMvmt_3p" )

	array<entity> jumpJetFXs
	array<string> attachments = [ "vent_left", "vent_right" ]
	int team                  = player.GetTeam()
	foreach ( attachment in attachments )
	{
		int friendlyID    = GetParticleSystemIndex( TEAM_JUMPJET_DBL )
		entity friendlyFX = StartParticleEffectOnEntity_ReturnEntity( player, friendlyID, FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( attachment ) )
		friendlyFX.SetOwner( player )
		SetTeam( friendlyFX, team )
		friendlyFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_FRIENDLY
		jumpJetFXs.append( friendlyFX )

		int enemyID    = GetParticleSystemIndex( ENEMY_JUMPJET_DBL )
		entity enemyFX = StartParticleEffectOnEntity_ReturnEntity( player, enemyID, FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( attachment ) )
		SetTeam( enemyFX, team )
		enemyFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_ENEMY
		jumpJetFXs.append( enemyFX )
	}

	OnThreadEnd(
		function() : ( jumpJetFXs, player )
		{
			foreach ( fx in jumpJetFXs )
			{
				if ( IsValid( fx ) )
					fx.Destroy()
			}

			if ( IsValid( player ) )
			{
				player.DisableSlowMo()
				player.EnableMantle()
				StopSoundOnEntity( player, "JumpPad_AirborneMvmt_3p" )
			}
		}
	)

	WaitFrame()

	wait 0.1
	//thread PlayerSkydiveFromCurrentPosition( player )
	while( !player.IsOnGround() )
	{
		WaitFrame()
	}

}


bool function Geyser_JumpPad_ShouldPushPlayerOrNPC( entity target )
{
	if ( target.IsTitan() )
		return false

	if ( IsSuperSpectre( target ) )
		return false

	if ( IsTurret( target ) )
		return false

	if ( IsDropship( target ) )
		return false

	return true
}


///////////////////////
///////////////////////
//// Updrafts

const string UPDRAFT_TRIGGER_SCRIPT_NAME = "skydive_dust_devil"
void function Updrafts_Init()
{
	array<entity> triggers = GetEntArrayByScriptName( UPDRAFT_TRIGGER_SCRIPT_NAME )
	foreach ( entity trigger in triggers )
	{
		if ( trigger.GetClassName() != "trigger_updraft" )
		{
			entity newTrigger = CreateEntity( "trigger_updraft" )
			newTrigger.SetOrigin( trigger.GetOrigin() )
			newTrigger.SetAngles( trigger.GetAngles() )
			newTrigger.SetModel( trigger.GetModelName() )
			newTrigger.SetScriptName( UPDRAFT_TRIGGER_SCRIPT_NAME )
			newTrigger.kv.triggerFilterTeamBeast = 1
			newTrigger.kv.triggerFilterTeamNeutral = 1
			newTrigger.kv.triggerFilterTeamOther = 1
			newTrigger.kv.triggerFilterUseNew = 1
			DispatchSpawn( newTrigger )
			trigger.Destroy()
		}
	}
}

void function BurnPlayerOverTime( entity player )
{
	Assert( IsValid( player ) )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
	player.EndSignal( "DeathTotem_PreRecallPlayer" )
	for ( int i = 0; i < 8; ++i )
	{
		//if ( !player.Player_IsInsideUpdraftTrigger() )
		//	break

		if ( !player.IsPhaseShifted() )
		{
			player.TakeDamage( 5, null, null, { damageSourceId = eDamageSourceId.burn, damageType = DMG_BURN } )
		}

		wait 0.5
	}
}
#endif

void function CodeCallback_PlayerEnterUpdraftTrigger( entity trigger, entity player )
{
	float entZ = player.GetOrigin().z
	//OnEnterUpdraftTrigger( trigger, player, max( -5750.0, entZ - 400.0 ) )
}


void function CodeCallback_PlayerLeaveUpdraftTrigger( entity trigger, entity player )
{
	//OnLeaveUpdraftTrigger( trigger, player )
}

#if SERVER
void function AddTrainToMinimap( entity mover )
{
	entity minimapObj = CreatePropScript( $"mdl/dev/empty_model.rmdl", mover.GetOrigin() )
	minimapObj.Minimap_SetCustomState( eMinimapObject_prop_script.TRAIN )
	minimapObj.SetParent( mover )
	SetTargetName( minimapObj, "trainIcon" )
	foreach ( player in GetPlayerArray() )
	{
		minimapObj.Minimap_AlwaysShow( 0, player )
	}
}
#endif

#if CLIENT
void function MinimapPackage_Train( entity ent, var rui )
{
	#if DEV
		printt( "Adding 'rui/hud/gametype_icons/sur_train_minimap' icon to minimap" )
	#endif
	RuiSetImage( rui, "defaultIcon", $"rui/hud/gametype_icons/sur_train_minimap" )
	RuiSetImage( rui, "clampedDefaultIcon", $"" )
	RuiSetBool( rui, "useTeamColor", false )
}

void function FullmapPackage_Train( entity ent, var rui )
{
	MinimapPackage_Train( ent, rui )
	RuiSetFloat2( rui, "iconScale", <1.5,1.5,0.0> )
	RuiSetFloat3( rui, "iconColor", <0.5,0.5,0.5> )
}
#endif

#if SERVER
// Creates a prop as a map element
entity function CreateEditorProp1(asset a, vector pos, vector ang, bool mantle = false, float fade = 2000, 
int realm = -1)
{
    entity e = CreatePropDynamic(a,pos,ang,SOLID_VPHYSICS,fade)
    e.kv.fadedist = fade
    if(mantle) e.AllowMantle()

    if (realm > -1) {
        e.RemoveFromAllRealms()
        e.AddToRealm(realm)
    }

    string positionSerialized = pos.x.tostring() + "," + pos.y.tostring() + "," + pos.z.tostring()
    string anglesSerialized = ang.x.tostring() + "," + ang.y.tostring() + "," + ang.z.tostring()

    e.SetScriptName("editor_placed_prop")
    e.e.gameModeId = realm
    printl("[editor]" + string(a) + ";" + positionSerialized + ";" + anglesSerialized + ";" + realm)

    return e
}

// Creates a zipline as a map element
void function CreateEditorZipline1( vector startPos, vector endPos )
{
	string startpointName = UniqueString( "rope_startpoint" )
	string endpointName = UniqueString( "rope_endpoint" )

	entity rope_start = CreateEntity( "move_rope" )
	SetEditorTargetName1( rope_start, startpointName )
	rope_start.kv.NextKey = endpointName
	rope_start.kv.MoveSpeed = 64
	rope_start.kv.Slack = 25
	rope_start.kv.Subdiv = "2"
	rope_start.kv.Width = "3"
	rope_start.kv.Type = "0"
	rope_start.kv.TextureScale = "1"
	rope_start.kv.RopeMaterial = "cable/zipline.vmt"
	rope_start.kv.PositionInterpolator = 2
	rope_start.kv.Zipline = "1"
	rope_start.kv.ZiplineAutoDetachDistance = "150"
	rope_start.kv.ZiplineSagEnable = "0"
	rope_start.kv.ZiplineSagHeight = "50"
	rope_start.SetOrigin( startPos )

	entity rope_end = CreateEntity( "keyframe_rope" )
	SetEditorTargetName1( rope_end, endpointName )
	rope_end.kv.MoveSpeed = 64
	rope_end.kv.Slack = 25
	rope_end.kv.Subdiv = "2"
	rope_end.kv.Width = "3"
	rope_end.kv.Type = "0"
	rope_end.kv.TextureScale = "1"
	rope_end.kv.RopeMaterial = "cable/zipline.vmt"
	rope_end.kv.PositionInterpolator = 2
	rope_end.kv.Zipline = "1"
	rope_end.kv.ZiplineAutoDetachDistance = "150"
	rope_end.kv.ZiplineSagEnable = "0"
	rope_end.kv.ZiplineSagHeight = "50"
	rope_end.SetOrigin( endPos )

	DispatchSpawn( rope_start )
	DispatchSpawn( rope_end )

	printl("[zipline][1]" + startPos)
	printl("[zipline][2]" + endPos)
}

// void function CreateEditorPhaseTunnel( vector startPos, vector endPos ) {

//     float prePlaceFXOffset = PHASE_TUNNEL_PLACEMENT_HEIGHT_STANDING
//     int fxid = GetParticleSystemIndex( PHASE_TUNNEL_PREPLACE_FX )
//     vector fxOrigin = player.GetOrigin() + ( <0,0,1> * prePlaceFXOffset )
//     entity fx = StartParticleEffectInWorld_ReturnEntity( fxid, startPos, <0, 0, 0> )

//     PhaseTunnelPortalData startData
// 	portalData.startOrigin = startPos
// 	portalData.startAngles = <0, 0, 0>
// 	portalData.endOrigin = endPos
// 	portalData.endAngles = <0, 0, 0>
// 	portalData.crouchPortal = false
// 	portalData.portalFX	= StartParticleEffectInWorld_ReturnEntity( fxid, startingPoint.origin + ( <0,0,1> * zOffset ), startingPoint.angles + <0,90,90> )

//     PhaseTunnelPathNodeData startPathData
//     startPathData.origin = <0, 0, 0>
//     startPathData.angles = <0, 0, 0>
//     startPathData.velocity = <0, 0, 0>
//     startPathData.wasInContextAction = false
//     startPathData.wasCrouched = false
//     startPathData.validExit = true
//     startPathData.time = 0

//     PhaseTunnelPathNodeData endPathData
//     endPathData.origin = <0, 0, 0>
//     endPathData.angles = AnglesCompose( angles, <0,180,0> )
//     endPathData.velocity = <0, 0, 0>
//     endPathData.wasInContextAction = false
//     endPathData.wasCrouched = false
//     endPathData.validExit = true
//     endPathData.time = 0

//     entity tunnelEnt = CreatePropScript( $"mdl/dev/empty_model.rmdl", startPos )



//     thread PhaseTunnel_CreateTriggerArea( tunnelEnt, startPos, endPos )
// 	thread PhaseTunnel_CreateTriggerArea( tunnelEnt, endPos, startPos )
// }

void function SetEditorTargetName1( entity ent, string name )
{
	ent.SetValueForKey( "targetname", name )
}
#endif


void function _CheckPoints_Init()
{
	#if SERVER && R5DEV
	AddClientCommandCallback( "cpTeleport", ClientCommand_TeleportToCurrentCp )
	AddClientCommandCallback( "cpAdd", ClientCommand_AddOneToCpCount )
	AddClientCommandCallback( "cpSub", ClientCommand_SubtractOneToCpCount)

    AddCallback_OnClientConnected( Player_Init )
	#endif
}

void function Player_Init( entity player ) {
    if( !IsValid( player ) )
		return

    file.cp_table[player] <- 0

    player.SetOrigin(file.cps_pos[file.cp_table[player]])
    player.SetAngles(file.cps_ang[file.cp_table[player]])

    thread Auto_Teleport(player)
}

bool function ClientCommand_TeleportToCurrentCp(entity player, array<string> args)
{

	if( !IsValid( player ) )
		return true

	// player.SetOrigin(file.cps_pos[file.current_cp])
	// player.SetAngles(file.cps_ang[file.current_cp])

    player.SetOrigin(file.cps_pos[file.cp_table[player]])
	player.SetAngles(file.cps_ang[file.cp_table[player]])

    return true
}

bool function ClientCommand_AddOneToCpCount(entity player, array<string> args)
{
	if( !IsValid( player ) )
		return true
	
	file.cp_table[player] = (file.cp_table[player] + 1) % 7

	// player.SetOrigin(file.cps_pos[file.current_cp])
	// player.SetAngles(file.cps_ang[file.current_cp])

    player.SetOrigin(file.cps_pos[file.cp_table[player]])
	player.SetAngles(file.cps_ang[file.cp_table[player]])

	return true
}

bool function ClientCommand_SubtractOneToCpCount(entity player, array<string> args)
{
	if( !IsValid( player ) )
		return true
	
	// if (file.current_cp > 0) {
	// 	file.current_cp = file.current_cp - 1
	// } else {
	// 	file.current_cp = 6
	// }

    file.cp_table[player] = (file.cp_table[player] + 6) % 7



	player.SetOrigin(file.cps_pos[file.cp_table[player]])
	player.SetAngles(file.cps_ang[file.cp_table[player]])

	return true
}

void function Auto_Teleport(entity player) {
    Assert( IsNewThread(), "Must be threaded off." )

	while ( true ) {
        if(!IsValid( player ))
            return

        
        float dist = Length(player.GetOrigin() - file.auto_tp)
        if( dist < 200 ) { 

            // Copied code, bad way to do it but idk how to call the function properly

            file.cp_table[player] = 6

            // player.SetOrigin(file.cps_pos[file.current_cp])
            // player.SetAngles(file.cps_ang[file.current_cp])

            player.SetOrigin(file.cps_pos[file.cp_table[player]])
            player.SetAngles(file.cps_ang[file.cp_table[player]])
        }
        WaitFrame()
    }
}

#if SERVER
// Spawns all the props
void function SpawnEditorProps()
{
    printl("---- INIT CHECKPOINT SCRIPTS ----")
    _CheckPoints_Init()
    // Written by mostly fireproof. Let me know if there are any issues!
    printl("---- NEW EDITOR DATA ----")
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4416,1152,-1280>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4416.07,1281,-1280>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4416.02,1280.83,-1023.45>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4224,1152,-1088>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <4096.91,1280.2,-1088.36>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <4096.98,1280.2,-959.99>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <4096.87,1280.48,-832.131>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <3648.85,1280.22,-1088.47>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <3648.77,1280.44,-831.537>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <3648.78,1280.53,-960.314>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4543.03,1152.04,-1024.24>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/city_pipe_grate_medium_128.rmdl", <4131.03,1091.77,-1071.99>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/city_pipe_grate_medium_128.rmdl", <4131.02,1220,-1072.2>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4287,1151.95,-1343.99>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3391.92,1023.07,-1023.63>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3391.98,1023.01,-768.136>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4416.04,1024.98,-1280.2>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4415.97,1024.94,-1024.33>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <4160.94,896.055,-1088.33>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <4160.93,896.298,-959.801>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <3712.78,896.348,-1088.52>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <3712.89,896.424,-960.159>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <3712.89,896.301,-831.665>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <4160.88,896.472,-832.002>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,1152,-1024>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.42,1599.95,-767.188>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,2560,-896>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3519.01,2112.02,-1024.14>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3264.68,2112.04,-1024.73>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.42,1343.94,-1024.82>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.21,1344.08,-767.389>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.29,1088.05,-767.294>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3264.89,1088.23,-1024.38>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3264.99,1599.92,-1024.15>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_01_no_lights.rmdl", <3391.07,2239.65,-959.883>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_01_no_lights.rmdl", <3327.11,2239.64,-959.729>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_01_no_lights.rmdl", <3263.06,2239.74,-959.773>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_01_no_lights.rmdl", <3455.05,2239.71,-959.872>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_01_no_lights.rmdl", <3519.22,2239.38,-959.877>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3391.9,2239.19,-832.574>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3392.06,2687.03,-832.231>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3400,2128,-1032>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,2048,-1024>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.02,2560,-896.211>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3520.97,2560.06,-896.235>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,2560,-640>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.92,2239,-831.977>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3520.05,2239,-831.992>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.17,2048,-1024.56>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3520.93,2047.84,-1024.34>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/city_pipe_grate_medium_128.rmdl", <3391.04,2943.73,-767.887>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/city_pipe_grate_medium_128.rmdl", <3391.04,3071.95,-768.273>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/containers/pelican_case_large.rmdl", <3391.17,3391.45,-704.098>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3391.76,2687.24,-704.599>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3519.17,2560.01,-704.555>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3391.99,3133,-692.065>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3264.89,2560.04,-704.445>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,2560,-448>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3392.07,2432.99,-704.088>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/containers/pelican_case_large.rmdl", <3391.26,3455.96,-704.666>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/containers/pelican_case_large.rmdl", <3391.28,3519.96,-704.688>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,2112,-768>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,3712,-704>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3516,2240,-576>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3268,2240,-576>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3711.05,4159.75,-768.199>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3711.19,4160.5,-1024.29>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,4480,-768>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3008.9,4927.98,-768.445>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3007.18,4928.16,-1023.45>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3328,5312,-896>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3648.98,5823.81,-1023.99>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3647.31,2239.95,-576.717>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3136.95,2240.07,-576.304>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3587.05,2136.02,-807.703>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3192.96,2135.96,-832.27>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.98,2368.99,-576.153>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3520.2,2368.97,-576.129>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3519.95,2112.97,-576.247>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3264,2112.97,-576.246>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3264,2240,-320>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3520,2240,-320>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3276,1940,-756>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3520,1944,-760>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3713,4160.01,-512.015>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3648.96,5824.02,-767.726>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3327.17,6144.06,-1408.55>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3327.15,6143.97,-1151.47>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,6592,-1344>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3392.95,7104.01,-1407.68>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3264,6656,-1216>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3520,6656,-1216>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3263.9,6528.61,-1216.79>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3519.92,6528.49,-1216.87>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,7040,-1152>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3392,7296,-1152>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_wall_curved_01.rmdl", <3583.28,7039.3,-1344.05>, <0,-45,30>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_wall_curved_01.rmdl", <3200.58,7039.19,-1344.13>, <0,45,30>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_lobby_sign_01.rmdl", <3400.17,6520.91,-1212.38>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/pipes/pipe_modular_painted_grey_256.rmdl", <3603.13,7063.72,-1424.41>, <0,-45,30>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/pipes/pipe_modular_painted_grey_256.rmdl", <3167.95,7071.06,-1428.34>, <0,45,30>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3136,7040,-1152>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3648,7040,-1152>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3392.92,7808.22,-1216.31>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3712,7744,-1024>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3391.03,7808.16,-959.811>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3520.06,6527.05,-960.295>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3264.06,6527.02,-960.188>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3839.01,8256.11,-1023.98>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3840.76,8255.9,-1279.36>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4160,8448,-960>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4351.01,8896.15,-896.07>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4351.07,8895.99,-1152.36>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4544.94,8896.05,-896.35>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4672,9152,-832>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6912,1088,-1472>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6975.39,1087.76,-1472.75>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6720,1088,-1344>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6976.77,1087.81,-1216.61>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6720,1088,-1088>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6911.78,1215.03,-1472.06>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6911.85,1215.45,-1215.18>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6911.99,960.927,-1472.37>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6912,960.394,-1215.08>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <7040,1088,-1216>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6976.97,1088.01,-959.759>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6912.07,959.011,-960.128>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6911.83,1216.98,-959.937>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6912,1088,-704>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6336,1088,-1088>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6784.52,1088.07,-1599.15>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6784.97,1087.97,-1344.25>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6655.88,959.1,-1088.42>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5824,1088,-1088>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/mobile_vehicle_01_wheel_02.rmdl", <6785,1088.05,-1088.07>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6655.94,1215.01,-1088.11>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6399.75,1215.03,-1088.05>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6143.81,1215.02,-1088.06>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5887.93,1215,-1088>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5631.79,1215.02,-1088.01>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5376.17,1215.01,-1088.04>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5119.86,1215.01,-1088.06>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4672,1152,-1280>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4928,1152,-1280>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6400.02,960.988,-1088.15>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6144.02,960.988,-1088.15>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5888.02,960.988,-1088.15>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5632.02,960.988,-1088.15>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5376.01,960.988,-1088.15>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5120.01,960.988,-1088.15>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4864.01,960.988,-1088.15>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6656.1,1215.03,-1344.21>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6399.93,1215.01,-1344.14>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4671.88,1279.17,-1280.54>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6143.93,1215.01,-1344.14>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5887.93,1215.01,-1344.14>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5631.85,1215.01,-1344.03>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/barriers/guard_rail_01_256.rmdl", <4544.6,1152.74,-1088.3>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5376.04,1215,-1344.03>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5119.97,1215,-1344.04>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4992,832,-1088>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4927.12,1279.53,-1280.05>, <0,-30,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4927.21,1279.43,-1087.76>, <0,-30,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/barriers/guard_rail_01_256.rmdl", <4544.25,1152.97,-1048.04>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4928.04,1280.79,-1280.62>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4928.01,1280.82,-1023.43>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4671.6,1279.09,-1024.1>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4928,896,-1280>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4863.26,959.338,-1280.14>, <0,-30,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4863.26,959.674,-1023.41>, <0,-30,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6656.03,960.987,-1344.16>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6400.02,960.986,-1344.17>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6144.02,960.986,-1344.17>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5888.02,960.986,-1344.17>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4672.19,1023.02,-1280.07>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5632.02,960.986,-1344.17>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5376.02,960.986,-1344.17>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5119.93,959.139,-1344.5>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4863.79,959.074,-1280.31>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4671.83,1023.09,-1023.62>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4563.58,1136.03,-1072.91>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4736.51,1151.99,-1088.86>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/canyonlands/canyonlands_zone_sign_03b.rmdl", <3263.24,2175.68,-192.562>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4480,960,-1088>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4480,1344,-1088>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6912,1088,-832>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6656,1088,-832>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6400,1088,-832>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6144,1088,-832>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5888,1088,-832>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5632,1088,-832>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5376,1088,-832>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5120,1088,-832>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4864,1088,-832>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4864,1344,-832>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6592.89,1088.17,-1344.42>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5183.98,9215,-959.98>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/firstgen/firstgen_pipe_256_darkcloth_01.rmdl", <5312.19,9088.95,-832.242>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/firstgen/firstgen_pipe_256_darkcloth_01.rmdl", <5055.76,9215.03,-832.087>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/firstgen/firstgen_pipe_128_goldfoil_01.rmdl", <5056.67,9088.02,-703.255>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4544.97,8895.77,-640.076>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/props/pathfinder_beacon_radar/pathfinder_beacon_radar_animated.rmdl", <4580.75,9239.76,-816.621>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/props/pathfinder_beacon_radar/pathfinder_beacon_radar_animated.rmdl", <3303.69,6576.85,-1328.41>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/props/pathfinder_beacon_radar/pathfinder_beacon_radar_animated.rmdl", <3304.24,2048.95,-1008.21>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/props/pathfinder_beacon_radar/pathfinder_beacon_radar_animated.rmdl", <4863.41,1008.26,-1264.76>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/props/pathfinder_beacon_radar/pathfinder_beacon_radar_animated.rmdl", <3303.93,3696.47,-688.877>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <3519.01,1152.11,-1280>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <3648.91,1279.59,-1216.03>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_large_01.rmdl", <4096.97,1279.76,-1215.95>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/IMC_base/imc_tech_panel_64_01.rmdl", <3423.22,6520.63,-1215.97>, <0,-90,0>, true, 8000, -1 )
//    CreateEditorProp1( $"mdl/props/loot_bin/loot_bin_02_animated.rmdl", <7719.04,9068.27,847.963>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6656,8256,1472>, <0,0,45>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6656,8064,1280>, <0,0,45>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6783.03,8255.91,1472.23>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6783.03,7999.91,1472.23>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6784.87,8000.09,1215.52>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6783.01,8255.97,1216.14>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6656,6912,1088>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5888,8704,4736>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6785,6528.03,1087.96>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <5183.85,9088.65,-960.748>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6144,8704,4736>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5376,9152,-704>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6400,8704,4736>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <6783.03,6272.04,1087.77>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4672,1344,-1088>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <5140,9152,-704>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <4672,1152,-1088>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/props/global_access_panel_button/global_access_panel_button_console_w_stand.rmdl", <5383.07,9152.08,-688.353>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/foliage/desertlands_alien_tree_02.rmdl", <3327.09,2304.04,-320.407>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/indust_struct_cooling_tower_support_01.rmdl", <3456.93,1343.94,-512.368>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/indust_struct_cooling_tower_support_01.rmdl", <3519,960.055,-511.934>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_cargo_container_small_02.rmdl", <3519.67,1152.7,-704.638>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <4223.97,1152.98,-704.193>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <4095.97,1152.98,-704.193>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <3968,1152.98,-704.201>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <3840,1152.98,-704.201>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <3712,1152.98,-704.201>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <3584,1152.98,-704.201>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <4480,1152.99,-768.17>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_ceiling_curved_01.rmdl", <4351.61,1152.9,-768.2>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_wall_curved_01.rmdl", <3391.78,2687.14,-448.46>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_wall_curved_01.rmdl", <3519.11,2559.84,-448.435>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_wall_curved_01.rmdl", <3264.92,2559.74,-448.29>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_window_frame_wall_curved_01.rmdl", <3392.12,2431.02,-448.128>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.91,2688.24,-448.328>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.72,2688.52,-448.456>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3392.94,2687.8,-320.271>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.11,2560.99,-320.101>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3519.48,2559.14,-319.955>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.85,2687.48,-319.984>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.96,2687.74,-320.113>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.65,2687.47,-896.539>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.94,2687.65,-768.04>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.62,2687.63,-639.314>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.65,2687.44,-575.486>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.63,2687.46,-896.562>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.76,2687.35,-768.033>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.69,2687.46,-639.515>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.61,2687.46,-575.424>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.81,2239.84,-1024.56>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.97,2239.78,-895.903>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.68,2239.8,-767.29>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.92,2239.66,-1024.2>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.86,2239.7,-895.583>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.81,2239.7,-767.495>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3519.22,1920.47,-1024.41>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3519.14,1920.49,-895.863>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3263.11,1920.43,-1024.14>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3263.18,1920.41,-895.602>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.95,1727.68,-1024.03>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.68,1727.77,-895.304>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.44,1727.87,-767.111>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3264.86,1727.54,-640.195>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3455.17,1280.53,-1023.85>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3455.11,1280.33,-895.682>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.75,1023.35,-1024.12>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <3520.75,1023.45,-895.637>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <4287.23,1280.59,-1088.24>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <4287.24,1280.59,-959.729>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <4287.4,1280.55,-895.418>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <4288.89,1023.57,-1088.16>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <4288.82,1023.56,-959.626>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <4288.68,1023.68,-831.34>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <6847.28,1216.53,-1472.44>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_vertical.rmdl", <6848.58,959.449,-1472.6>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <4992.42,1216.6,-1280.68>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <4992.67,1216.7,-1152.23>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <4992.48,1216.64,-1023.4>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <4799.8,1023.23,-1280.6>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <4799.68,1023.06,-1151.91>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <4799.77,1023.19,-1023.46>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.68,1023.35,-1280.69>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.5,1023.19,-1152.31>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.67,1279.18,-1280.46>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.72,1279.06,-1152.21>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.03,2432.14,-896.214>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.22,2432.13,-767.385>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.4,2432.09,-639.206>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3263.03,2432.1,-896.229>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3263.17,2432.23,-767.5>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3263.44,2432.13,-639.182>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3263.1,3136.29,-703.675>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.16,3136.3,-703.556>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3519.48,3136.18,-575.168>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3263.18,3136.4,-575.589>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.08,4032.24,-1024.97>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.42,4032.83,-895.633>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.34,4032.56,-767.241>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.26,4032.38,-639.111>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.1,4032.15,-511.017>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.55,4032.78,-383.7>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.51,4288.77,-1024.39>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.53,4288.8,-895.706>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.42,4288.59,-767.312>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.38,4288.52,-639.237>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.13,4288.2,-511.029>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3712.11,4288.16,-383.019>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.56,4799.34,-1024.61>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.4,4799.21,-895.87>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.51,4799.4,-767.369>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.67,4799.58,-639.156>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.55,5055.33,-1023.41>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.76,5055.69,-895.079>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.44,5055.2,-767.791>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3007.58,5055.48,-639.253>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.41,5696.58,-1024.71>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.55,5696.82,-896.169>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.44,5696.65,-767.377>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.15,5696.75,-639.36>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.53,5952.62,-1024.58>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.66,5952.74,-895.874>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.49,5952.51,-767.288>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3648.22,5952.24,-639.056>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.56,6015.53,-1408.76>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.47,6015.22,-1280.34>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.52,6015.36,-1151.4>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.7,6015.53,-1023.17>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.59,6271.48,-1408.75>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.4,6271.29,-1280.37>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.36,6271.3,-1151.69>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3327.61,6271.5,-1023.23>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3647.22,6528.43,-1216.44>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3647.13,6528.47,-1087.87>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3647.32,6528.34,-959.35>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3647.55,6528.22,-831.134>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3135.08,6528.39,-1216.08>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3135.24,6528.31,-1087.43>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3135.39,6528.33,-959.283>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3135.72,6528.15,-831.05>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.67,7679.38,-1216.71>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.53,7679.12,-1087.9>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.61,7679.4,-959.303>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.76,7679.54,-831.143>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.47,7935.17,-1216.14>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.62,7935.36,-1087.33>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.72,7935.51,-959.176>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/industrial_support_beam_16x144_filler.rmdl", <3391.84,7935.71,-831.056>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <3328.02,2240.93,-960.357>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <3456.09,2240.97,-960.222>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <3391.96,2240.99,-959.85>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5759.01,8703.93,4735.87>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5888.04,8832.98,4735.83>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6144.02,8832.98,4735.83>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6400.02,8832.98,4735.83>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6528.93,8704.22,4735.7>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5888.04,8575.17,4735.44>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5759.2,8639.51,4735.65>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5759.14,8768.27,4735.56>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5823.72,8832.87,4735.6>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5952.18,8832.91,4735.63>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6015.93,8832.94,4735.67>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6079.94,8832.94,4735.66>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6208.07,8832.94,4735.66>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6272.01,8832.94,4735.65>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6336.01,8832.94,4735.65>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6464.01,8832.94,4735.65>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6528.84,8768.39,4735.62>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <6528.89,8639.7,4735.67>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/guard_rail_painted_metal_dirty_01_caution.rmdl", <5823.78,8575.08,4735.67>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3455.22,3648.58,-703.762>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3327.18,3648.49,-703.697>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3391.25,3648.56,-703.654>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3455.2,4416.58,-767.811>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3391.18,4416.54,-767.797>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3327.12,4416.42,-767.775>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3391.46,5248.42,-895.273>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3327.35,5248.58,-895.508>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3263.18,5248.41,-895.603>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3455.15,6528.49,-1343.82>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3391.16,6528.47,-1343.72>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desrtlands_icicles_06.rmdl", <3327.08,6528.34,-1343.79>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_large_liquid_tank_ring_01.rmdl", <6207.75,8512.92,4607.68>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_large_liquid_tank_ring_01.rmdl", <6464.21,8255.8,3199.04>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_large_liquid_tank_ring_01.rmdl", <6592.16,8127.86,2367.02>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_train_station_turnstile_01.rmdl", <5055.13,9151.86,-704.463>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3007.04,7104.03,-1152.28>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3007.05,6976.11,-1152.31>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3071.94,6911.05,-1152.31>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3199.91,6913,-1151.99>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3712.12,6912.99,-1152.04>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3584.03,6913,-1152.04>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3071.56,7168.77,-1152.46>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3199.89,7168.82,-1152.57>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3263.11,7232,-1152.45>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3263.11,7360,-1152.45>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3520.79,7360.04,-1152.61>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3520.79,7232.1,-1152.6>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3584.07,7168.92,-1152.39>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3712.22,7168.9,-1152.38>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3776.85,7104.19,-1152.49>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3776.82,6975.75,-1152.51>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/lightpole_desertlands_city_01.rmdl", <3391.78,7679.28,-704.654>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_train_track_sign_01.rmdl", <4352.05,8769,-640.075>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/lightpole_desertlands_city_01.rmdl", <3839.47,8127.19,-768.265>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/lightpole_desertlands_city_01.rmdl", <3392.66,7936.75,-704.055>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/lightpole_desertlands_city_01.rmdl", <3840.65,8384.66,-768.376>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/lightpole_desertlands_city_01.rmdl", <4352.65,9024.76,-639.979>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/mobile_vehicle_01_wheel_02.rmdl", <3392.08,2687.02,-192.201>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/mobile_vehicle_01_wheel_02.rmdl", <3392.15,2560.97,-192.207>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_wedge.rmdl", <4543.13,8895.98,-383.511>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_wedge.rmdl", <4544.96,8895.79,-383.809>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/wall_city_barred_concrete_192_01.rmdl", <3648.97,6656.02,-1216.23>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/wall_city_barred_concrete_192_01.rmdl", <3135,6655.96,-1216.06>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/wall_city_corner_concrete_64_01.rmdl", <3648.46,6783.39,-1216.64>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/wall_city_corner_concrete_64_01.rmdl", <3647.16,6528.18,-1216.51>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/wall_city_corner_concrete_64_01.rmdl", <3136.92,6784.01,-1216.39>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/wall_city_corner_concrete_64_01.rmdl", <3136.46,6528.86,-1216.21>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_lobby_desk_01.rmdl", <4544.84,8896.02,-192.546>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_train_station_sign_01.rmdl", <3392.8,2687.42,-127.842>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_sign_01.rmdl", <3519,1152,-640.003>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/curb_parking_concrete_destroyed_01.rmdl", <3455.22,6528.52,-1216.33>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_train_station_sign_04.rmdl", <3391.16,6528.55,-1216.01>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_train_station_sign_04.rmdl", <5056.64,9152.76,-703.901>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_train_track_magnetic_beam_01.rmdl", <5503.51,9151.13,-704.057>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_train_track_magnetic_beam_01.rmdl", <3392.85,2623.67,-128.402>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_02.rmdl", <3392.66,2687.45,-448.511>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_02.rmdl", <4544,8896.26,-128.964>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_02.rmdl", <4544.57,8896.78,-0.251444>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_plantroom_rack_02.rmdl", <4544.21,8896.98,128.058>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <-511.452,-575.171,64.109>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3648.88,5951.73,-512.393>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3648.97,5823.95,-512.227>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3135.8,6528.85,-704.486>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3263.9,6528.86,-704.499>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3391.92,6528.87,-704.493>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3520.03,6528.86,-704.507>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3327.25,6015.5,-896.439>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3327.1,6143.99,-896.444>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3007.1,4799.58,-511.895>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3007.03,4928.22,-511.951>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3712.94,4288.35,-256.044>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3712.98,4160.2,-256.068>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.2,3136.96,-447.803>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3392.06,3136.99,-447.889>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3391,7679.99,-704.095>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3391.01,7808.06,-704.096>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3840.99,8384.14,-768.09>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3840.99,8255.89,-768.1>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4351.04,8768.27,-639.893>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4351,8896.07,-639.973>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.88,1728.03,-512.47>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.88,1600.05,-512.47>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.88,1471.97,-512.468>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.88,1343.96,-512.466>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.88,1215.96,-512.466>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.88,1087.95,-512.466>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.06,1024.93,-512.354>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3392.11,1024.95,-512.308>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4543.03,1023.94,-768.228>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4543.03,1151.97,-768.229>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4543.96,1023,-768.088>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4416.03,1023.01,-768.1>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4416.22,1280.95,-768.235>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4288.09,1280.96,-768.249>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3648.02,1023.3,-704.71>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3775.99,1023.02,-704.184>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3903.96,1023.02,-704.196>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4031.94,1023.02,-704.21>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4159.94,1023.02,-704.21>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4287.95,1023.04,-704.286>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3519.85,1280.64,-704.754>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3648,1280.64,-704.77>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3776.04,1280.65,-704.763>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3904,1280.65,-704.758>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4032,1280.65,-704.756>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <4160.01,1280.66,-704.753>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3456.98,1407.89,-704.175>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/research_station_storage_shelf_02.rmdl", <-2240.55,9663.17,-3456.07>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4480.01,1471.1,-1088.44>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4352.4,1408.25,-1088.88>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4671.85,1471.1,-1088.41>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4799.27,1407.46,-1088.42>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4799.05,1152.1,-1088.31>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4672.28,1535.04,-1088.03>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <4479.98,1535,-1088.01>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3520.03,2687.13,-448.498>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3392.02,2687.12,-448.474>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.74,2688.54,-448.4>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3264.9,2559.96,-448.436>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3519.03,2431.89,-448.228>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3519.05,2559.96,-448.314>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3520.47,2431.29,-448.518>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/desertlands_city_train_station_railing_02.rmdl", <3391.82,2431.09,-448.375>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/indust_struct_cooling_tower_godrays_01.rmdl", <4480.18,7104.05,3583.02>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/indust_struct_cooling_tower_godrays_01.rmdl", <6272.25,8447.98,5311.03>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/indust_struct_cooling_tower_godrays_01.rmdl", <6272.68,8447.48,4479.48>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/indust_struct_cooling_tower_godrays_01.rmdl", <6592.49,8127.7,3327.18>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/colony/antenna_03_colony.rmdl", <3392.85,6527.65,-704.392>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/colony/ventilation_unit_01_black.rmdl", <5503.47,9087.21,-704.314>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/colony/ventilation_unit_01_black.rmdl", <5503.52,9215.23,-704.42>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/colony/ventilation_unit_01_black.rmdl", <5503.46,9151.18,-704.194>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_05.rmdl", <3392.58,3712.07,-704.813>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/desertlands/highrise_small_apt_signage_03.rmdl", <2560.85,7808.45,-1216.28>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/signs/desertlands_city_newdawn_sign_01.rmdl", <3392.83,7168.56,-1151.96>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <13056,-448,-2880>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp1( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <6656,5248,1088>, <0,90,0>, true, 8000, -1 )

}



#endif