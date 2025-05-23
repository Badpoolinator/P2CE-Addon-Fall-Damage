// script created by Rip Rip Rip (https://www.youtube.com/@Rip-Rip-Rip)
// version 1.00

::health <- null
::regenenabled <- null
::healthpersistence <- null
function Init()
{
    ::Dev <- Dev()
    Dev.msg("Initialising script...")

    ::SCOPE <- Storage.CreateScope("RipRipRip_FallDamage_V1")

    local interval = Entities.CreateByClassname("logic_timer")
    interval.__KeyValueFromString("targetname", "fd_interval")
    interval.__KeyValueFromFloat("RefireTime", 0.01)
    interval.ConnectOutput("OnTimer", "Interval")
    EntFire("fd_interval", "Enable")

    local auto = Entities.CreateByClassname("logic_auto")
    auto.ConnectOutput("OnLoadGame", "Init_LoadFromSave")
}
function Init_PlayerSetup()
{
    Dev.msg("Setting up player...")

    player = GetPlayer()

    local maxhealth = SCOPE.GetInt("player_maxhealth")
    if(maxhealth == 0) {  // presume first time script setup
        Dev.msg("Performing first time setup...")
        SCOPE.SetInt("player_maxhealth", player.GetMaxHealth())
        SCOPE.SetInt("player_health", player.GetMaxHealth())
        SCOPE.SetInt("player_regenenabled", 0)
        SCOPE.SetInt("player_health_persistenceenabled", 0)
        regenenabled = 0
        healthpersistence = 0
    } else {
        Dev.msg("Grabbing previous values...")
        player.SetMaxHealth(SCOPE.GetInt("player_maxhealth"))
        regenenabled = SCOPE.GetInt("player_regenenabled")
        healthpersistence = SCOPE.GetInt("player_health_persistenceenabled")
        if(healthpersistence == 1) player.SetHealth(SCOPE.GetInt("player_health"))
        else SCOPE.SetInt("player_health", player.GetMaxHealth())
    }

    health = player.GetMaxHealth()
    playerHUDUpdate()

    local proxy = Entities.CreateByClassname("logic_playerproxy")   // required to remove boots from player
    proxy.__KeyValueFromString("targetname", "fd_proxy")
    EntFire("fd_proxy", "RemoveBoots")
    EntFire("fd_proxy", "Kill", "", FrameTime())
}
function Init_LoadFromSave()
{
    ::SCOPE <- Storage.CreateScope("RipRipRip_FallDamage_V1")
    SCOPE.SetInt("player_health", health)
    regenenabled = SCOPE.GetInt("player_regenenabled")
    healthpersistence = SCOPE.GetInt("player_health_persistenceenabled")
    playerHUDUpdate()
}
function playerDetectHealthChange()
{
    if(regenenabled == 1) {
        local health_difference = abs(health - player.GetHealth())
        if(health_difference > 0) {
            health = player.GetHealth()
            SCOPE.SetInt("player_health", health)
            SendToPanorama("Drawer_NavigateToTab", health.tostring())
        }
    } else {
        local health_difference = player.GetMaxHealth() - player.GetHealth()
        if(health_difference > 0) {
            health -= health_difference
            SCOPE.SetInt("player_health", health)
            player.SetHealth(player.GetMaxHealth())
            if(health <= 0) {
                local hurt = Entities.CreateByClassname("point_hurt")
                hurt.__KeyValueFromString("targetname", "fd_hurt")
                hurt.__KeyValueFromString("DamageTarget", "!player")
                hurt.__KeyValueFromInt("Damage", 99999)
                hurt.__KeyValueFromInt("DamageType", 32)

                EntFire("fd_hurt", "TurnOn")
                EntFire("fd_hurt", "Hurt", "", FrameTime())
                EntFire("fd_hurt", "TurnOff", "", FrameTime() * 2)
                EntFire("fd_interval", "Kill")
                health = 0
                SCOPE.SetInt("player_health", player.GetMaxHealth())
            }
            SendToPanorama("Drawer_NavigateToTab", health.tostring())
        }
    }
}
function playerHUDUpdate()
{
    // use these to get around event-definition.js not being reloaded when "panorama_reload" is ran
    SendToPanorama("Drawer_NavigateToTab", health.tostring())
    SendToPanorama("Drawer_ExtendAndNavigateToTab", player.GetMaxHealth().tostring())
}

::setup_hasfired <- false
::player <- null
function Interval()
{
    if(player != null) {   // wait for player to exist before doing anything
        if(setup_hasfired == false) {
            Init_PlayerSetup()
            setup_hasfired = true
        }
    } else return
    
    playerDetectHealthChange()
    if(GetDeveloperLevel() > 0) Dev.DisplayOnscreenInfo()
}

function SetMaxPlayerHealth(val)
{
    if(typeof(val) != "integer") {
        Dev.msg_error("Invalid input type! Only integer values are accepted.")
        return
    } else if(val <= 0) {
        Dev.msg_error("Invalid input size! Health must be >= 0!")
        return
    }
    
    player.SetMaxHealth(val)
    player.SetHealth(val)
    health = player.GetMaxHealth()

    SCOPE.SetInt("player_maxhealth", health)
    SCOPE.SetInt("player_health", health)
    playerHUDUpdate()

    Dev.msg("Set player's maximum health to " + val + "!")
}
function DoHealthRegeneration(val)
{
    if(typeof(val) != "bool") {
        Dev.msg_error("Invalid input type! Only boolean values ('true'/'false') are accepted.")
        return
    }
    if(val == true) {
        Dev.msg("Enabled health regeneration!")
        val = 1
    } else if(val == false) {
        Dev.msg("Disabled health regeneration!")
        val = 0
    } 
    
    regenenabled = val
    SCOPE.SetInt("player_regenenabled", regenenabled)
    health = player.GetMaxHealth()
    player.SetHealth(health)
    SCOPE.SetInt("player_health", health)
    Dev.msg(SCOPE.GetInt("player_health"))
    SendToPanorama("Drawer_NavigateToTab", health.tostring())
}
function DoHealthPersistence(val)
{
    if(typeof(val) != "bool") {
        Dev.msg_error("Invalid input type! Only boolean values ('true'/'false') are accepted.")
        return
    }
    if(val == true) {
        Dev.msg("Enabled health persistence!")
        SCOPE.SetInt("player_health", health)
        val = 1
    } else if(val == false) {
        Dev.msg("Disabled health persistence!")
        val = 0
    } 
    healthpersistence = val
    SCOPE.SetInt("player_health_persistenceenabled", healthpersistence)
}
function ResetScript()
{
    SCOPE.ClearAll()
    Dev.msg("Reset script storage! Please restart the map to avoid any errors...")
}

// class containing useful dev functions
class Dev{
    function msg(msg) {
        printl("[FALL DAMAGE] " + msg)
    }
    function msg_error(msg) {
        printl("[FALL DAMAGE - ERROR] " + msg)
    }
    function DisplayOnscreenInfo() {
        DebugDrawScreenText(0.01, 0.535, "=== DEV:", 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.55, "ACTUAL HEALTH: " + player.GetHealth(), 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.565, "INTERNAL HEALTH: " + health, 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.58, "INTERNAL HEALTH (SCOPED): " + SCOPE.GetInt("player_health"), 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.595, "IS REGEN ENABLED: " + regenenabled, 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.61, "IS REGEN ENABLED (SCOPED): " + SCOPE.GetInt("player_regenenabled"), 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.625, "MAX HEALTH: " + player.GetMaxHealth(), 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.64, "MAX HEALTH (SCOPED): " + SCOPE.GetInt("player_maxhealth"), 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.655, "IS HEALTH PERSISTENCE ENABLED: " + healthpersistence, 255, 150, 255, 255, 0.05)
        DebugDrawScreenText(0.01, 0.67, "IS HEALTH PERSISTENCE ENABLED (SCOPED): " + SCOPE.GetInt("player_health_persistenceenabled"), 255, 150, 255, 255, 0.05)
    }
}

Init()