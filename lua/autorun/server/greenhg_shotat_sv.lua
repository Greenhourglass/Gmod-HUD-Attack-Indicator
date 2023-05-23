
--[[------------------------------------------------------
		Serverside Initialization
--]]------------------------------------------------------

resource.AddSingleFile( "materials/greenhg_combat/hud/greenhg_shotpointer.png" ) 
resource.AddSingleFile( "materials/greenhg_combat/hud/greenhg_shotpointer02.png" ) 

util.AddNetworkString( "Greenhg_ShotInd" )

if !ConVarExists( "sv_greens_attackindicator_enable" ) then
	CreateConVar( "sv_greens_attackindicator_enable", "1", { 128, 256 }, "Enable or force disable the HUD attack indicator for all players." )
end
local cvarEnable = GetConVar( "sv_greens_attackindicator_enable" )

local function shouldCallAttack(ply)
	if ply then
		if cvarEnable:GetBool() and IsValid(ply) and ply:IsPlayer() and ply:GetInfoNum("cl_greens_attackindicator_enable", 1) == 1 then
			return true
		else
			return false
		end
	else
		if cvarEnable:GetBool() then
			return true
		else
			return false
		end
	end
end

--[[------------------------------------------------------
		greenhgCombatShotAt( attacker, bullet )
	A bullet is fired, and nearly misses someone
--]]------------------------------------------------------

local function shotAt1( attacker, bullet )
	if shouldCallAttack() then 
		for i,victim in pairs(player.GetAll()) do
			if shouldCallAttack(victim) and !(attacker == victim) and IsValid(attacker) and IsValid(victim) then
			
				local victimOrgin = victim:GetPos()
				--Get the position between the target's eyes and feet
				local myPos = victimOrgin + (( victim:EyePos() - victimOrgin ) / 2 )
				local targDistToSqr = myPos:DistToSqr( bullet.Src )
				local aimatmeVector = myPos - bullet.Src
				
				if targDistToSqr < (bullet.Distance + 256)^2 then -- if the distance is less than the bullet's max distance + 256
					local compareAng = aimatmeVector:Angle()
					local fireAng = bullet.Dir:Angle()
					local missAng = compareAng - fireAng
					missAng:Normalize()
					
					local missToSqr = (missAng.p^2) + (missAng.y^2)
					
					--print( missToSqr, 8100/(targDistToSqr/6400) ) --debug
					
				--[[----------------------------------
						The HUD Indicator part
				--]]----------------------------------
					
					--[[ 	2025 = 45^2		90000 = 300^2
							8100 = 90^2		5625 = 75^2	]]
					if ( missToSqr <= 2025 and targDistToSqr <= 90000 ) or
						( targDistToSqr > 90000 and ( missToSqr <= 8100/(targDistToSqr/5625) )) then
						
						local trdata = {}
						
						--[[if math.random(1,2) == 1 then
							trdata.start 	= bullet.Src
						else
							trdata.start 	= attacker:EyePos()
						end
						
						if math.random(1,2) == 1 then
							trdata.endpos 	= victim:EyePos()
						else
							trdata.endpos 	= myPos
						end]]
						
						trdata.start 	= bullet.Src
						trdata.endpos 	= victim:EyePos()
						
						trdata.filter 	= {attacker,victim}
						trdata.mask 	= MASK_SHOT --or MASK_BLOCKLOS_AND_NPCS
						
						local trace = util.TraceLine( trdata )
						
						if !trace.Hit then
							if IsValid(victim) and victim:IsPlayer() then 
								net.Start("Greenhg_ShotInd")
								net.WriteEntity( attacker )
								net.Send( victim )
							end
						end
					end
				end
			end
		end
	end
end
hook.Add("EntityFireBullets","greenhg_combat_shotat1", shotAt1 ) 

--[[------------------------------------------------------
		greenhgCombatShot( victm, dmginfo )
	Someone takes damage
--]]------------------------------------------------------

local function shotAt2( victim, dmginfo )
	local attacker = dmginfo:GetAttacker()
	if shouldCallAttack(victim) and IsValid(attacker) and IsValid(victim) and victim:IsPlayer() then 
		net.Start("Greenhg_ShotInd")
		net.WriteEntity( attacker )
		net.Send( victim )
	end
end
hook.Add("EntityTakeDamage","greenhg_combat_shotat2", shotAt2 ) 

