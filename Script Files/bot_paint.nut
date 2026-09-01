::__PaintBotCosmetics <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (!player || !player.IsBotOfType(1337)) return;
		
		EntFireByHandle(player, "RunScriptCode", @"
			local tags = {};  self.GetAllBotTags(tags);

			foreach (index, tag in tags)
			{
				if (!startswith(tag, ""paint|"")) continue;
				
				try
				{
					local args = split(tag, ""|"");
					if (!args.len()) continue;
					
					for (local wearable = self.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
					{
						if (wearable.GetClassname() != ""tf_wearable"") continue;
						
						local id = NetProps.GetPropInt(wearable, ""m_AttributeManager.m_Item.m_iItemDefinitionIndex"");
						if (id != args[1].tointeger()) continue;
						
						local paint = null;
						if (args.len() == 3)
							paint = args[2].tointeger();
						else if (args.len() == 5)
						{
							local r = args[2].tointeger();
							local g = args[3].tointeger();
							local b = args[4].tointeger();
							
							paint = (b) | (g << 8) | (r << 16);
						}
						
						wearable.AddAttribute(""set item tint rgb"", paint, -1);
					}
				}
				catch (e) {}
			}
		", 0, null, null);
	}
};
__CollectGameEventCallbacks(__PaintBotCosmetics);