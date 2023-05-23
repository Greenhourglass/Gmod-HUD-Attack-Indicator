
--[[------------------------------------------------------
		Clientside Initialization
--]]------------------------------------------------------

if !ConVarExists( "cl_greens_attackindicator_enable" ) then
	CreateConVar( "cl_greens_attackindicator_enable", "1", { 128, 512 }, "Enable the HUD attack indicator on the client. Must be enabled serverside as well" )
end
local cvarEnable = GetConVar( "cl_greens_attackindicator_enable" )

if !ConVarExists( "cl_greens_attackindicator_size" ) then
	CreateConVar( "cl_greens_attackindicator_size", "256", { 128 }, "Size of HUD indicator" )
end
local cvarSize = GetConVar( "cl_greens_attackindicator_size" )

 
if !greenhgCombat then
	greenhgCombat = { IsValid = function(self) return true end }
end

function greenhgCombat:ShotIndicatorStart(attacker)
	if cvarEnable:GetBool() and IsValid(attacker) then
		greenhgCombat.currentAttackers[attacker] = { UnPredictedCurTime() + 3, attacker:GetPos() }
	end
end
greenhgCombat.currentAttackers = {}
greenhgCombat.indicatorMat = Material( "greenhg_combat/hud/greenhg_shotpointer02.png", "smooth" )


net.Receive( "Greenhg_ShotInd", function( len )
	local attacker = net.ReadEntity()
	greenhgCombat:ShotIndicatorStart(attacker)
end )

--[[------------------------------------------------------
		Drawing the HUD indicator
--]]------------------------------------------------------

local function shotIndicatorDrawHUD()
	if cvarEnable:GetBool() then 
		surface.SetMaterial( greenhgCombat.indicatorMat )
		local size = cvarSize:GetFloat()
		
		for ent,data in pairs( greenhgCombat.currentAttackers ) do
			if data then 
				local fade = ( ( data[1] - UnPredictedCurTime() ) * 60 )
				if !IsValid(ent) or fade <= 0 or ent == LocalPlayer() then 
					greenhgCombat.currentAttackers[ent] = nil
				else
					if fade > 180 then fade = 180 end
					local rotate = ((EyePos() - data[2]):Angle().y - EyeAngles().y) + 180
					
					surface.SetDrawColor( 255, 255, 255, fade )
					surface.DrawTexturedRectRotated( ScrW()/2, ScrH()/2, size, size, rotate )
				end
			end
		end
	end
end
hook.Add("HUDPaint","greenhg_combat_shothudind", shotIndicatorDrawHUD )
