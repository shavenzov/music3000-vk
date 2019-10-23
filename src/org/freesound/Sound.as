package org.freesound
{
	import com.adobe.serialization.json.JSONDecoder;
	
	import flash.events.EventDispatcher;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class Sound extends EventDispatcher
	{
		public var soundLoaded:Boolean; // Sound information loaded flag (not audio data)
		public var fullSoundLoaded : Boolean;
		public var soundAnalysis:Boolean; // Sound analysis loaded flag (not audio data)
		
		
		// Sound properties
		public var info:Object = new Object();
		public var analysis:Object = new Object();
		
		public function Sound()
		{
		}
		
		public function loadFullInfo( info : Object ) : void
		{
			this.info = info;
			fullSoundLoaded = true;
		}	
		
		public function loadInfo(info:Object):void
		{
			this.info = info;
			this.soundLoaded = true;
		}
		
		public function loadAnalysis(analysis:Object):void
		{
			this.analysis = analysis;
			this.soundAnalysis = true;
		}
	}
}