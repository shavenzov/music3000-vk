package org.freesound
{
	import com.adobe.serialization.json.JSONDecoder;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.clearInterval;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	
	import mx.rpc.events.ResultEvent;
	
	import com.dataloaders.DataLoader;
	import com.dataloaders.LoaderRecord;
	import org.freesound.Sound;
	
	public class SoundLoader extends DataLoader
	{
		/**
		 * Величина задержки перед отправлением запроса 
		 */		
		private static const WAIT_TIME : Number = 250.0;
		private static const CHECK_INTERVAL : Number = 50;
		
		private var timer_id : int = -1;
		
		private const waiting : Vector.<LoaderRecord> = new Vector.<LoaderRecord>();
		
		public function SoundLoader()
		{
			super();
		}
		
		override public function clear():void
		{
			super.clear();
			clearTimer();
			waiting.length = 0;
		}	
		
		override public function cancel( data : Object ) : Boolean
		{
			return cancelRequestInLists( data, Vector.<Vector.<LoaderRecord>>( [ waiting, inqueue ] ) );
		}
		/*
		public function soundIsLoading( s : Sound ) : Boolean
		{
			var result : Vector.<int> = getObjectIndexes( Vector.<LoaderRecord>( [ waiting, inqueue, loading ] ), s );
			return result != null;
		}	
		*/
		override protected function itemComplete(e:Event):void
		{
			
				var loader : URLLoader = URLLoader( e.currentTarget );
				var index  : int = getRecordIndexByLoader( loading, loader );
				var record : LoaderRecord = loading[ index ];
				var s      : Sound = Sound( record.data );
				
				var data:String = URLLoader( record.loader ).data.toString();
				var jd:JSONDecoder = new JSONDecoder(data,true);
				
				if ( record.params.type == "sound_info" ){	
					
					s.loadFullInfo(jd.getValue());
					
					// Notify client that info is available
					s.dispatchEvent(new ResultEvent("GotSoundInfo"));
					
				}else if ( record.params.type == "sound_analysis"){
					s.loadAnalysis(jd.getValue());
					
					// Notify client that analysis is available
					s.dispatchEvent(new ResultEvent("GotSoundAnalysis"));
				}
				
			
			super.itemComplete( e );
		}
		
		override protected function itemIOError(e:IOErrorEvent):void
		{	
			var loader : URLLoader = URLLoader( e.currentTarget );
			var index  : int = getRecordIndexByLoader( loading, loader );
			var record : LoaderRecord = loading[ index ];
			var s      : Sound = Sound( record.data );
			
			if ( record.params.type == "sound_info" )
			{
				s.dispatchEvent( new IOErrorEvent( 'ErrorSoundInfo', e.bubbles, e.cancelable, e.text, 0 ) );
			}	
			else
			{
				s.dispatchEvent( new IOErrorEvent( 'ErrorSoundAnalysis', e.bubbles, e.cancelable, e.text, 0 ) );
			}	
			
			
			super.itemComplete( e );
		}
		
		public function loadAnalysis( s : Sound ) : void
		{
			var rec : LoaderRecord;
			rec = new LoaderRecord( s, null, { type : "sound_analysis", req : _getSoundAnalysis( s.info[ 'id' ] ) } );
			pushToWait( rec );
		}	
		
		public function loadInfo( s : Sound ) : void
		{
			var rec : LoaderRecord;
			
			rec = new LoaderRecord( s, null, { type : "sound_info", req : _getSoundFromRef( s.info[ 'ref' ] ) } );
			pushToWait( rec );
		}	
		
		override protected function initLoad(record:LoaderRecord):void
		{
			var loader : URLLoader = new URLLoader();
			record.loader = loader;
			
			super.initLoad( record );
			
			loader.load( URLRequest( record.params.req ) );
		}	
		
		private function pushToWait( record : LoaderRecord ) : void
		{
			waiting.push( record );
			setTimer();
		}	
		
		private function _getSoundFromRef( ref : String ) : URLRequest
		{
			var request : URLRequest = new URLRequest( ref );
			    request.data = new URLVariables();
				request.data.api_key = ApiKey.key; 
			
			return request;
		}
		
		private function _getSoundFromId( id : int ) : URLRequest
		{
			return _getSoundFromRef("http://www.freesound.org/api/sounds/" + id.toString());
		}
		
		private function _getSoundAnalysis( id : int, filter:String = "" ) : URLRequest
		{
			var request : URLRequest = new URLRequest( "http://www.freesound.org/api/sounds/" + id.toString() + "/analysis/" + filter );
			    request.data = new URLVariables();
				request.data.api_key = ApiKey.key;
			
			return request;
		}
		
		private function onTick() : void
		{
			for ( var i : int = 0; i < waiting.length; i ++ )
			{
				var r : LoaderRecord = waiting[ i ];
				
				if ( ( getTimer() - r.time ) > WAIT_TIME )
				{
					waiting.splice( i, 1 );
					putToQueue( r );
				}
			}	
			
			if ( waiting.length == 0 )
			{
				clearTimer();
			}	
		}	
		
		private function setTimer() : void
		{
			if ( timer_id == -1 )
			{
				timer_id = setInterval( onTick, CHECK_INTERVAL );
			}	
		}
		
		private function clearTimer() : void
		{
			if ( timer_id != -1 )
			{
				clearInterval( timer_id );
				timer_id = -1;
			}	
		}	
		
	}
}