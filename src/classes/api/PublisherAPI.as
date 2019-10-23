package classes.api
{
	import flash.utils.ByteArray;
	
	import classes.api.errors.APIError;
	import classes.api.events.AMFErrorEvent;
	import classes.api.events.AMFErrorLayer;
	import classes.api.events.PublisherEvent;
	import classes.api.events.PublisherProcessEvent;
	import classes.api.events.PublisherUploadEvent;

	public class PublisherAPI extends CustomEventDispatcher
	{
		public static const FORMAT_WAVE : String = 'wave';
		public static const FORMAT_MP3  : String = 'mp3';
		
		public static const QUALITY_16_BIT_44100 : String = '16_44100';
		public static const QUALITY_24_BIT_44100 : String = '24_44100';
		public static const QUALITY_32_BIT_44100 : String = '32_44100';
		
		public static const QUALITY_320_K        : String = '320k';
		public static const QUALITY_192_K        : String = '192k';
		public static const QUALITY_128_K        : String = '128k';
		
		public static const MP3_QUALITY          : Array = [ QUALITY_128_K, QUALITY_192_K, QUALITY_320_K ];
		public static const WAVE_QUALITY         : Array = [ QUALITY_16_BIT_44100, QUALITY_24_BIT_44100, QUALITY_32_BIT_44100 ];
		
		private var api : MainAPIImplementation;
		
		/**
		 * Идентификатор паблишера 
		 */		
		private var _publisher_id : String;
		
		public function PublisherAPI()
		{
			super();
			api = MainAPI.impl;
		}
		
		public function get publisher_id() : String
		{
			return _publisher_id;
		}
		
		private function call( func : String, callback : Function, ...params ) : void
		{
			if ( ! _publisher_id )
				throw new Error( 'Не получен идентификатор паблишера.', 100 );
			
			params.unshift( func, callback, _publisher_id ); //К каждому запросу добавляем идентификатор паблишера
			api.call.apply( this, params );
		}
		
		private function onBegan( responds : Object, call : Call ) : void
		{
			if ( responds is String )
			{
				_publisher_id = String( responds );
				
				dispatchEvent( new PublisherEvent( PublisherEvent.BEGIN ) );
				
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'Ошибка Publisher.begin', int( responds ), call, AMFErrorLayer.COMMAND ) );
		}
		
		public function begin( project_id : int ) : void
		{
			api.call( 'Publisher.begin', onBegan, project_id );
		}
		
		private function onUploaded( responds : Object, call : Call ) : void
		{
			if ( responds is Number )
			{
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'Ошибка Publisher.upload', int( responds ), call, AMFErrorLayer.COMMAND ) );
				return;
			}
			
			dispatchEvent( new PublisherUploadEvent( PublisherUploadEvent.UPLOAD, responds.wrote, responds.size, responds.total, responds.done ) );
		}
		
		public function upload( data : ByteArray, blockSize : uint, total : uint ) : void
		{
			call( 'Publisher.upload', onUploaded, data, blockSize, total );
		}
		
		private function onProcessed( responds : Object, call : Call ) : void
		{
			trace( 'onProcessed', traceObject( responds ) );
			
			if ( responds is Number )
			{
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'Ошибка Publisher.process', int( responds ), call, AMFErrorLayer.COMMAND ) );
				return;
			}
			
			if ( responds.return_var != 0 )
			{
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'Ошибка выполнения Publisher.process на стороне сервера', int( responds.return_var ), call, AMFErrorLayer.COMMAND ) );
				return;
			}
			
			dispatchEvent( new PublisherProcessEvent( PublisherProcessEvent.PROCESSED, responds.url ) );
		}
		
		public function process( params : Object ) : void
		{
			call( 'Publisher.process', onProcessed, params );
		}
		
		private function onPublished( responds : Object, call : Call ) : void
		{
			if ( responds is Number )
			{				
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'Ошибка Publisher.publish', int( responds ), call, AMFErrorLayer.COMMAND ) );
				return;
			}
			
			dispatchEvent( new PublisherEvent( PublisherEvent.PUBLISHED, responds ) );
		}
		
		public function publish( url : String ) : void
		{
			call( 'Publisher.publish', onPublished, url );
		}
		
		private function onEnded( responds : Object, call : Call ) : void
		{
			var code : int = responds as int;
			
			if ( code && ( code != APIError.OK ) )
			{				
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'Ошибка Publisher.end', int( responds ), call, AMFErrorLayer.COMMAND ) );
				return;
			}
			
			_publisher_id = null;
			
			dispatchEvent( new PublisherEvent( PublisherEvent.END ) );
		}
		
		public function end() : void
		{
			call( 'Publisher.end', onEnded );
		}
	}
}