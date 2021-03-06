package ;
import enet.ENet;
import enet.ENetEvent;
import enet.Server;
import entities.Spawn;
import flixel.FlxG;
import gamemodes.BaseGamemode;
import gamemodes.DefaultHooks;
import gevents.GenEvent;
import gevents.JoinEvent;
import gevents.LeaveEvent;
import gevents.ReceiveEvent;
import gevents.RespawnEvent;
import gevents.SetTeamEvent;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import networkobj.NReg;
import sys.io.File;
import hxudp.UdpSocket;
import ext.FlxMarkup;
import ext.FlxTextExt;

/**
 * ...
 * @author Ohmnivore
 */
class SkullServer extends Server
{
	//public var s:UdpSocket;
	public var internal_ip:String;
	
	public var config:Map<String, String>;
	public var manifestURL:String;
	
	public var peermap:Map<Player, Int>;
	public var playermap:Map<Int, Player>;
	
	public var id:Int = 1;
	
	public var s_name:String;
	public var players:Int = 0;
	public var players_max:Int;
	
	public function new(IP:String = null, Port:Int = 0, Channels:Int = 3, Players:Int = 32) 
	{
		playermap = new Map<Int, Player>();
		peermap = new Map<Player, Int>();
		
		super(IP, Port, Channels, Players);
		
		internal_ip = ENet.getLocalIP();
		
		Msg.addToHost(this);
		
		Msg.Manifest.data.set("url", manifestURL);
		
		players_max = Std.parseInt(Assets.config.get("maxplayers"));
		s_name = Assets.config.get("name");
		
		Masterserver.init();
		Masterserver.register(s_name);
		
		//s = new UdpSocket();
		//s.create();
		//s.bind(1945);
		//s.setNonBlocking(true);
		//s.setEnableBroadcast(true);
		//s.connect(ENet.BROADCAST_ADDRESS, 1990);
	}
	
	//public function updateS():Void
	//{
		//var b = Bytes.alloc(80);
		//s.receive(b);
		//var msg:String = new BytesInput(b).readUntil(0);
		//
		//if (msg == "get_info")
		//{
			//var info:String = '';
			//info += '[';
			//info += '"$s_name", ';
			//var mapname:String = Reg.mapname;
			//info += '"$mapname", ';
			//var gm_name:String = Reg.gm.name;
			//info += '"$gm_name", ';
			//info += '$players, ';
			//info += '$players_max, ';
			//info += '"$internal_ip"';
			//info += ']';
			//
			//s.sendAll(Bytes.ofString(info));
		//}
	//}
	
	public function sendChatMsg():Void
	{
		var t:String = Reg.chatbox.text.text;
		Reg.chatbox.text.text = "";
		
		t = StringTools.trim(t);
		
		if (t.length > 0)
		{
			t = "Server: " + t;
			
			//Send to all
			Msg.ChatToClient.data.set("id", 0);
			Msg.ChatToClient.data.set("message", t);
			Msg.ChatToClient.data.set("color", 0xffff0000);
			
			for (ID in Reg.server.peermap.iterator())
			{
				Reg.server.sendMsg(ID, Msg.ChatToClient.ID, 1, ENet.ENET_PACKET_FLAG_RELIABLE);
			}
			
			//Add to local chatbox
			Reg.chatbox.addMsg(t, Msg.ChatToClient.data.get("color"));
		}
	}
	
	public function sendMsgToAll(MsgID:Int, Channel:Int = 0, Flags:Int = 0):Void
	{
		for (p in playermap.keys())
		{
			sendMsg(p, MsgID, Channel, Flags);
		}
	}
	
	override public function onPeerConnect(e:ENetEvent):Void
	{
		super.onPeerConnect(e);
		
		players++;
		
		if (players > players_max)
		{
			peerDisconnect(e.ID, false);
		}
		
		else
		{
			sendMsg(e.ID, Msg.Manifest.ID, 1, ENet.ENET_PACKET_FLAG_RELIABLE);
			
			Masterserver.setPlayers(players, players_max);
		}
	}
	
	override public function onPeerDisonnect(e:ENetEvent):Void 
	{
		super.onPeerDisonnect(e);
		
		players--;
		
		Masterserver.setPlayers(players, players_max);
		
		Reg.gm.dispatchEvent(new LeaveEvent(LeaveEvent.LEAVE_EVENT, e));
	}
	
	public function announce(Text:String, Markup:Array<FlxMarkup>):Void
	{
		var t:FlxTextExt = new FlxTextExt(0, 0, FlxG.width, Text, 12, false, Markup);
		
		//Add locally
		Reg.announcer.addMsg(Text, Markup);
		
		//Send to clients
		Msg.Announce.data.set("message", t.text);
		Msg.Announce.data.set("markup", t.ExportMarkups());
		
		for (ID in peermap.iterator())
		{
			sendMsg(ID, Msg.Announce.ID, 1, ENet.ENET_PACKET_FLAG_RELIABLE);
		}
	}
	
	override public function onReceive(MsgID:Int, E:ENetEvent):Void 
	{
		if (MsgID == Msg.PlayerInfo.ID)
		{
			Reg.gm.dispatchEvent(new JoinEvent(JoinEvent.JOIN_EVENT, E));
		}
		
		if (MsgID == Msg.PlayerInput.ID)
		{
			var p:Player = playermap.get(E.ID);
			
			try
			{
				p.s_unserialize(Msg.PlayerInput.data.get("serialized"));
			}
			catch (e:Dynamic)
			{
				
			}
		}
		
		if (MsgID == Msg.ChatToServer.ID)
		{
			var p:Player = playermap.get(E.ID);
			
			if (p != null)
			{
				var t:String = Msg.ChatToServer.data.get("message");
				
				t = StringTools.trim(t);
				
				if (t.length > 0)
				{
					t = p.name + ": " + t;
					
					Msg.ChatToClient.data.set("id", p.ID);
					Msg.ChatToClient.data.set("color", p.header.color);
					Msg.ChatToClient.data.set("message", t);
					
					Reg.chatbox.addMsg(t, p.header.color);
					
					for (ID in peermap.iterator())
					{
						sendMsg(ID, Msg.ChatToClient.ID, 1, ENet.ENET_PACKET_FLAG_RELIABLE);
					}
				}
			}
		}
		
		if (MsgID == Msg.BoardRequest.ID)
		{
			BaseGamemode.scores.sendAllToPlayer(E.ID);
		}
		
		if (MsgID == Msg.SpawnRequest.ID)
		{
			var p:Player = playermap.get(E.ID);
			var t:Int = Msg.SpawnRequest.data.get("team");
			
			if (p.canSpawn)
			{
				if (Reg.gm.teams.length >= t)
				{
					var team:Team = Reg.gm.teams[t];
					
					if (p.graphicKey != team.graphicKey || p.team != t)
					{
						p.team = t;
						Reg.gm.dispatchEvent(new SetTeamEvent(SetTeamEvent.SETTEAM_EVENT,
							p, Reg.gm.teams[t]));
					}
				}
				
				p.respawn();
				
				Reg.gm.dispatchEvent(new GenEvent(RespawnEvent.RESPAWN_EVENT, p));
			}
		}
		
		super.onReceive(MsgID, E);
		
		Reg.gm.dispatchEvent(new ReceiveEvent(ReceiveEvent.RECEIVE_EVENT, MsgID, E));
		
		E = null;
	}
}