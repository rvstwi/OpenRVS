//new in 0.8
//this class will handle receiving text from each server and parsing it to learn basic info about the server
class OpenClientBeaconReceiver extends ClientBeaconReceiver transient;

var OpenMultiPlayerWidget Widget;

//call this function with the ip and server beacon port (regular port + 1000) of the server to get info from
function QuerySingleServer(OpenMultiPlayerWidget OMPW, coerce string sIP, coerce int sPort)
{
	local IpAddr Addr;
	if ( Widget == none )//get a reference to the widget to send info back to
		Widget = OMPW;
	StringToIpAddr(sIP,Addr);//turn the string to an IP
	Addr.Port = sPort;
	BroadcastBeacon(Addr);
}

//0.8
//receive text
//super it but also check if it's response to the "REPORT" broadcast
//if so, parse and send to OpenMultiPlayerWidget
event ReceivedText(IpAddr Addr, string Text)
{
	local int pos;//position in the current string
	local string szSecondWord;//second word in the message
	local string szThirdWord;//third word in the message
	local string sNumP,sMaxP,sGMode,sMapName,sSvrName;
	local string sModName;//1.3
	local bool bSvrLocked;//1.5

	super.ReceivedText(Addr,Text);

	if ( left(Text,len(BeaconProduct)+1) ~= (BeaconProduct$" ") )
	{
		// Decode the second word to determine the port number of the server
		szSecondWord = mid(Text,len(BeaconProduct)+1);
		Addr.Port = int(szSecondWord);
		// Check for the string KEYWORD
		szThirdWord = mid(szSecondWord,InStr(szSecondWord," ")+1);
		if ( left(szThirdWord,len(KeyWordMarker)+1) ~= ( KeyWordMarker$" " ) )
		{
			//if we got to this stage, it's a REPORT response
			//start szthirdword at the first symbol for GrabOption() to work
			szThirdWord = mid(szThirdWord,InStr(szThirdWord, Chr(182)));
			//send the string to ParseOption() with it as first argument, key to look for the second
			//eg numplayers = ParseOption(szThirdWord,"keyfornumplayers");
			//need to overwrite GetKeyValue because it looks for "=" when we need to look for the space between the marker and the value
			//GrabOption also leaves a space at the end as well as strips the initial symbol
			//so need to put that symbol back on, and strip the space in GrabOption
			sNumP = ParseOption(szThirdWord,NumPlayersMarker);
			sMaxP = ParseOption(szThirdWord,MaxPlayersMarker);
			sGMode = ParseOption(szThirdWord,GameTypeMarker);
			sMapName = ParseOption(szThirdWord,MapNameMarker);
			sSvrName = ParseOption(szThirdWord,SvrNameMarker);
			sModName = ParseOption(szThirdWord,ModNameMarker);//1.3 - sModName string added to function in MP menu
			bSvrLocked = bool(ParseOption(szThirdWord,LockedMarker));//1.5 - locked info received here
			Widget.ReceiveServerInfo(IpAddrToString(Addr),sNumP,sMaxP,sGMode,sMapName,sSvrName,sModName,bSvrLocked);//send received info back to server list
			class'OpenLogger'.static.Debug("Server " $ sSvrName $ " at " $ IpAddrToString(Addr) $ " is playing map " $ sMapName $ " in game mode type " $ sGMode $ ". Players: " $ sNumP $ "/" $ sMaxP, self);
		}
	}
}

//overridden from parent
//need to strip out the final space from result
//also need to add the removed symbol back into result
function bool GrabOption(out string Options, out string Result)//¶I1 OBSOLETESUPERSTARS.COM ¶F1 RGM
{
	local string pilcrow;
	pilcrow = Chr(182);//¶

	if ( Left(Options,1) == pilcrow )
	{
		// Get result.
		Result = Mid(Options,1);
		if( InStr(Result, pilcrow) >= 0 )//I1 OBSOLETESUPERSTARS.COM ¶F1 RGM
			Result = Left(Result,InStr(Result, pilcrow)-1);//I1 OBSOLETESUPERSTARS.COM//0.8 strip the space
		Result = pilcrow $ Result;//0.8 add the symbol back in - ¶I1 OBSOLETESUPERSTARS.COM

		// Update options.
		Options = Mid(Options,1);//I1 OBSOLETESUPERSTARS.COM ¶F1 RGM
		if( InStr(Options, pilcrow) >= 0 )
			Options = Mid(Options,InStr(Options, pilcrow));//¶F1 RGM
		else
			Options = "";
		return true;
	}
	else
	{
		class'OpenLogger'.static.Debug("GRABOPTION FALSE", self);
		return false;
	}
}

//overridden from parent
//instead of looking for "=", need to look for first space
function GetKeyValue(string Pair, out string Key, out string Value)
{
	if ( InStr(Pair," ") >= 0 )
	{
		Key   = Left(Pair,InStr(Pair," "));
		Value = Mid(Pair,InStr(Pair," ")+1);
	}
	else
	{
		Key   = Pair;
		Value = "";
	}
}