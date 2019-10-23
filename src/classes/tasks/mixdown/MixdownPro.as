package classes.tasks.mixdown
{
	import com.audioengine.calculations.Calculation;
	import com.audioengine.core.AudioData;
	import com.thread.SimpleTask;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	
	import classes.SequencerImplementation;
	import classes.api.PublisherAPI;
	import classes.api.data.ProjectInfo;
	import classes.api.events.AMFErrorEvent;
	import classes.api.events.PublisherEvent;
	import classes.api.events.PublisherProcessEvent;
	import classes.api.events.PublisherUploadEvent;
	import classes.api.social.vk.tasks.PublishAudioPro;
	
	public class MixdownPro extends SimpleTask
	{
		public static const INITIALIZING : int = 2;
		public static const MIXDOWNING   : int = 5;
		public static const MIXDOWNED    : int = 8;
		public static const PROCESSING   : int = 10;
		public static const PUBLISHING   : int = 12;
		public static const ENDING       : int = 15;
		
		/**
		 * Размер буфера для импорта проекта в аудиофайл ( в фреймах ) 
		 */		
		private static const MIXDOWN_BUFFER_SIZE : uint = AudioData.framesToBytes( Calculation.MAX_DATA_WIDTH );
		
		/**
		 * Данные на сервер отправляются блоками по BLOCK_SIZE 
		 */		
		private static const UPLOAD_BLOCK_SIZE : uint = 1048576; //1mb
		
		/**
		 * Секвенсер 
		 */		
		private var seq : SequencerImplementation;
		
		/**
		 * Паблишер
		 */		
		private var pub : PublisherAPI;
		
		/**
		 * Общий размер всех данных 
		 */		
		private var _total : uint;
		
		/**
		 * Общий размер обработанных данных 
		 */		
		private var _progress : uint;
		
		private var data : ByteArray = new ByteArray();
		private var dataLength : uint;
		
		/**
		 * Накопительный буфер для сбора необходимого количества данных перед отправкой 
		 */		
		private var buffer : ByteArray;
		
		/**
		 * Параметры кодирования 
		 */		
		private var params : Object;
		
		/**
		 * Информация о миксе 
		 */		
		private var info : ProjectInfo;
		
		/**
		 * Ссылка на скачивание 
		 */		
		private var _download_url : String;
		
		/**
		 * Идентификатор альбома в котором был сохранен микс, в случае публикации микса в "Мои аудиозаписи" 
		 */		
		public var album_id : String;
		
		/**
		 * Публиковать ли сведенный файл в моих аудиозаписях VK
		 */		
		private var publish_to_vk : Boolean;
		
		private var from : Number;
		private var to   : Number;
		
		public function MixdownPro( info : ProjectInfo, seq : SequencerImplementation, params : Object, publish_to_vk : Boolean, from : Number, to : Number )
		{
			super();
			
			this.seq = seq;
			
			this.pub = new PublisherAPI();
			this.pub.addListener( AMFErrorEvent.ERROR, onPubError, this );
			
			this.params = params;
			this.info   = info;
			this.publish_to_vk = publish_to_vk;
			
			this.from = from;
			this.to   = to;
		}
		
		public function get download_url() : String
		{
			return _download_url;
		}
		
		public function get statusString():String
		{
			var s : String;
			
			switch ( _status )
			{
				case SimpleTask.NONE :
				case INITIALIZING    :	
					                   s = 'Подготовка...';
									   break;
				
				case MIXDOWNING      : s = 'Сведение...';
					                   break;
				
				case PROCESSING      : s = 'Кодирование...';
					                   break;
				
				case PUBLISHING      : s = 'Публикация...';
					                   break;
				
				case ENDING          : s = 'Завершение...';
					                   break;
			}
			
			return s;
		}
		
		public function clear():void
		{
			if ( ! info )
			{
				return;
			}
			
			if ( seq.mixdowning )
			{
			  seq.endMixdown();
			}
			
			if ( vk_publisher )
			{
				vk_publisher.removeEventListener( Event.CHANGE, onVKPublisherStatusChanged );
				vk_publisher.cancel();
				vk_publisher = null;
			}
			
			buffer = null;
			data   = null;
			
			pub.removeAllObjectListeners( this );
			pub = null;
			
			seq = null;
			
			params = null;
			info = null;
			_status = SimpleTask.DONE;
		}
		
		override protected function next() : void
		{
			switch( _status )
			{
				case SimpleTask.NONE :  begin();
					                    break;
				
				case INITIALIZING :
				case MIXDOWNING : process();
					              break;
				
				case MIXDOWNED : encode();
					             break;
				
				case PROCESSING : if ( publish_to_vk )
				                  {
					                publish();
				                  }
				                  else
								  {
									  end();  
								  }
					              
					              break;
				
				case PUBLISHING : end();
					              break;
				
				case SimpleTask.ERROR : 
				case SimpleTask.DONE  : clear();
					 break;
			}
			
			super.next();
		}
		
		private var vk_publisher : PublishAudioPro;
		
		private function onVKPublisherStatusChanged( e : Event ) : void
		{
			if ( vk_publisher.status == SimpleTask.ERROR )
			{
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, 'Ошибка публикации', 100 ) );
				_status = SimpleTask.ERROR;
				next();
				return;
			}
			
			if ( vk_publisher.status == SimpleTask.DONE )
			{
				vk_publisher.removeEventListener( Event.CHANGE, onVKPublisherStatusChanged );
				
				album_id = vk_publisher.album_id;
				
				vk_publisher = null;
				next();
				return;
			}
		}
		
		private function publish() : void
		{
			_status = PUBLISHING;
			
			vk_publisher = new PublishAudioPro( pub, info );
			vk_publisher.addEventListener( Event.CHANGE, onVKPublisherStatusChanged );
			vk_publisher.run();
		}
		
		private function onBegan( e : PublisherEvent ) : void
		{
			pub.removeListener( PublisherEvent.BEGIN, onBegan );
			next();
		}
		
		private function begin() : void
		{
			_status = INITIALIZING;
			_total  = seq.beginMixDown( from, to );
			
			//Инициализируем работу паблишера
			pub.addListener( PublisherEvent.BEGIN, onBegan, this );
			pub.begin( info.id );
		}
		
		private function onUploaded( e : PublisherUploadEvent ) : void
		{
			pub.removeListener( PublisherUploadEvent.UPLOAD, onUploaded );
			buffer = null;
			
			if ( _progress == _total )
			{
				_status = MIXDOWNED;
			}
			
			next();
		}
		
		private function onPubError( e : AMFErrorEvent ) : void
		{
			_status = SimpleTask.ERROR;
			
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, e.text, e.errorID ) );
			
			next();
		}
		
		private function upload() : void
		{
			pub.addListener( PublisherUploadEvent.UPLOAD, onUploaded, this );
			
			pub.upload( buffer, buffer.length, _total );
		}
		
		private function onEncoded( e : PublisherProcessEvent ) : void
		{
			_download_url = e.url;
			
			pub.removeListener( PublisherProcessEvent.PROCESSED, onEncoded );
			next();
		}
		
		private function encode() : void
		{
			_status = PROCESSING;
			
			pub.addListener( PublisherProcessEvent.PROCESSED, onEncoded, this );
			pub.process( params );
		}
		
		private function onEnded( e : PublisherEvent ) : void
		{
			pub.removeListener( PublisherEvent.END, onEnded );
			
			_status = SimpleTask.DONE;
			
			dispatchEvent( new Event( Event.COMPLETE ) ) ;
			
			next();
		}
		
		private function end() : void
		{
			_status = ENDING;
			
			pub.addListener( PublisherEvent.END, onEnded, this );
			pub.end();
		}
		
		/**
		 * Количество вызовов mixdown за один process 
		 */		
		private static const numMixdownPerOperations : int = 5;
		
		private function process():void
		{ 
			var i    : int = 0;
			var done : Boolean;
			
			_status = MIXDOWNING;
			
			if ( ! buffer )
			{
				buffer = new ByteArray();
			}
			
			do
			{
				 mixdown();
				 i ++;
				 done = ( _progress == _total );
			}
			while( ! done && ( i < numMixdownPerOperations ) )
				  
			  
			if ( ( buffer.length >= UPLOAD_BLOCK_SIZE ) || done )
			{
			  upload();	
			}
			else
			{
			  callLater( next );
			}
			  
			dispatchEvent( new ProgressEvent( ProgressEvent.PROGRESS, false, false, _progress, _total ) ); 
		}
		
		private function mixdown() : void
		{
			dataLength  = Math.min( _total - _progress, MIXDOWN_BUFFER_SIZE );
			data.length = dataLength;
			
			try
			{	
				seq.mixdown( data, dataLength );	
			}
			catch( e : Error )
			{	
				_status = SimpleTask.ERROR;
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, e.message, e.errorID ) );
				next();
			}
			
			_progress += dataLength;
			buffer.writeBytes( data );
		}
	}
}