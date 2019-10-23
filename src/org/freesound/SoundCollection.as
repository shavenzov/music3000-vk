package org.freesound
{
	import com.adobe.serialization.json.JSONDecoder;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import mx.rpc.events.ResultEvent;
	
	public class SoundCollection extends EventDispatcher
	{
		
		private var http : URLLoader = new URLLoader();
		public var listLoaded:Boolean = false;
		private var fullResultsMode:Boolean = false;
		
		public var n:int = 0;
		
		// Sound list
		public var soundList : Vector.<Sound> = new Vector.<Sound>();
		public var num_results:int = 0;
		public var num_pages:int = 0;
		public var previous:String = "";
		public var next:String = "";
		public var request_id:int = -1;
		
		public var current_page:int = 1;
		public var currentObtainedResults:int = 0;
		public var maxResults:int = -1;
		
		public function SoundCollection()
		{
			http.addEventListener( Event.COMPLETE, resultHandler );
			http.addEventListener( IOErrorEvent.IO_ERROR, faultHandler );
		}
		
		private static function setURLVariables( obj : Object ) : URLVariables
		{
			var result : URLVariables = new URLVariables();
			
			for ( var prop : String in obj )
			{ 
				result[ prop ] = obj[ prop ];
			}
			
			return result;
		}	
			
		public function getSoundsFromRef(ref:String, params:Object = null):void
		{
			var request : URLRequest = new URLRequest( ref );
			   
			if ( ! params )
			{
				request.data = new URLVariables();
			}	
			else
			{
				request.data = setURLVariables( params );
			}	
			
			request.data.api_key = ApiKey.key;

			http.load( request );	
		}
		
		public function getSoundsFromUser(name:String):void
		{
			this.currentObtainedResults = 0;
			this.getSoundsFromRef("http://www.freesound.org/api/people/" + name + "/sounds");
		}
		
		public function getSoundsFromPackId(id:int):void
		{
			this.currentObtainedResults = 0;
			this.getSoundsFromRef("http://www.freesound.org/api/packs/" + id.toString() + "/sounds");
		}
		
		public function getSimilarSoundsFromSoundId(id:int, preset:String = "music", num_results:int = 15):void
		{
			var params:Object = {}
			params.preset = preset
			params.num_results = num_results
			
			this.currentObtainedResults = 0;
			this.getSoundsFromRef("http://www.freesound.org/api/sounds/" + id.toString() + "/similar", params);
		}
		
		public function getSoundsFromQuery(params:Object):void
		{
			var request : URLRequest = new URLRequest( "http://www.freesound.org/api/sounds/search" );
			    request.data = setURLVariables( params );
				
			this.current_page = 1;
			if (params.hasOwnProperty("p")){
				this.current_page = params.p;
			}
			
			request.data.api_key = ApiKey.key;
			this.currentObtainedResults = 0;
			
			http.load( request );
		}
		
		public function getNSoundsFromQuery(params:Object, maxResults:int):void
		{
            var request : URLRequest = new URLRequest( "http://www.freesound.org/api/sounds/search" );
			    request.data = setURLVariables( params );
			
			
				request.data.api_key = ApiKey.key;
			
			this.current_page = 1;
			if (params.hasOwnProperty("p")){
				this.current_page = params.p;
			}
			
			this.enableFullResultsMode();
			this.currentObtainedResults = 0;
			this.maxResults = maxResults;
			this.soundList = new Vector.<Sound>; // Reset results list (before query)
				
			http.load( request );
		}
		
		public function enableFullResultsMode():void
		{
			this.fullResultsMode = true;	
		}
		
		public function disableFullResultsMode():void
		{
			this.fullResultsMode = false;	
		}
		
		public function nextPage():void
		{
			
			if (next != null){
				this.getSoundsFromRef(this.next);
				this.current_page = this.current_page + 1;
			}
		}
		
		public function previousPage():void
		{
			if (previous != null){
				this.getSoundsFromRef(this.previous);
				this.current_page = this.current_page - 1;
			}
		}
		
		// Result handler
		private function resultHandler(event : Event):void
		{

			var data:String = http.data.toString();
			var jd:JSONDecoder = new JSONDecoder(data,true);

			this.request_id = (int)(jd.getValue().request_id);
			
			// Fill data structure
			if (!fullResultsMode){
				this.soundList = new Vector.<Sound>();
			}
			
			for (var i:int=0;i<jd.getValue().sounds.length;i++) {
				var s:Sound = new Sound();
				s.loadInfo(jd.getValue().sounds[i]);
				
				if (this.maxResults != -1){
					if (this.currentObtainedResults < this.maxResults){
						this.soundList.push(s);
						this.currentObtainedResults = this.currentObtainedResults + 1;
						
					}else{
						i = jd.getValue().sounds.length; // If we already got N desired results, break the for loop
					}
				}else{
					this.soundList.push(s);
					this.currentObtainedResults = this.currentObtainedResults + 1;
				}
			}
			
			if (this.maxResults != -1){
				this.num_results = this.currentObtainedResults;
			}else{
				this.num_results = jd.getValue().num_results; // Only useful in queries (not from references)
			}
			this.num_pages = jd.getValue().num_pages; // Only useful in queries (not from references)
			this.previous = jd.getValue().previous;
			this.next = jd.getValue().next;
			
			if (!fullResultsMode){
				// Notify client that info is available
				this.listLoaded = true;
				this.dispatchEvent(new ResultEvent("GotSoundCollection"));
			
			}else{
				
				if (this.maxResults != -1){ // If N max of results is set
				
					if (this.currentObtainedResults >= this.maxResults){ // If we already have N desired results
						// Notify client that info is available
						this.listLoaded = true;
						this.disableFullResultsMode();
						this.maxResults = -1;
						this.num_pages = 1;
						this.current_page = 1;
						this.dispatchEvent(new ResultEvent("GotSoundCollection"));
						
					} else if (this.next != null){
						// If we havent still got N desired results but there are pages remeaining
						this.nextPage();
						if (this.num_pages != 0){
							trace("Gathering information... (" + ((this.current_page/this.num_pages)*100).toPrecision(3) + "%)");
						}else{
							trace("Gathering information...");
						}
					}else{
						// There are less than N results and we already got them
						this.listLoaded = true;
						this.disableFullResultsMode();
						this.maxResults = -1;
						this.num_pages = 1;
						this.current_page = 1;
						this.dispatchEvent(new ResultEvent("GotSoundCollection"));
					}
				}else if (this.next != null){ // If we dont have a N max results, we just go to the next page if it exists
					this.nextPage();
					if (this.num_pages != 0){
						trace("Gathering information... (" + ((this.current_page/this.num_pages)*100).toPrecision(3) + "%)");
					}else{
						trace("Gathering information...");
					}
				}else{
					// If there is no max results set and there are no more pages
					this.listLoaded = true;
					this.dispatchEvent(new ResultEvent("GotSoundCollection"));
				}
			}	
		}
		
		public function cancel() : void
		{
			http.close();
		}	
		
		// Fault handler
		private function faultHandler(event: IOErrorEvent):void
		{
			this.dispatchEvent(event);
		}
		
	}
}