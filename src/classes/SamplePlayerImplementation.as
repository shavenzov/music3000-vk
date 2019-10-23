package classes
{
	import classes.events.SamplePlayerEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	public class SamplePlayerImplementation extends EventDispatcher
	{
		private var _sound        : Sound;
		private var _channel      : SoundChannel;
		private var _sndTransform : SoundTransform;
		
		private var _timerId      : int = -1;
		
		private var _url          : String;
		private var _length       : Number;
		
		/**
		 * Во время предыдущей операции произошла ошибка 
		 */		
		private var _error : Boolean;
		
		private var _playedOneTime : Boolean;
		private var _opened : Boolean;
		
		/**
		 * Текущий владелец SamplePlayer 
		 */		
		public var owner : Object;
		
		public function SamplePlayerImplementation()
		{
			super();
			
			_sndTransform = new SoundTransform();
		}
		
		public function get wasPlayedOneTime() : Boolean
		{
			return _playedOneTime;
		}
		
		private function setTimer() : void
		{
			if ( _timerId == -1 )
			{
			  _timerId = setInterval( onTick, 50.0 );
			}	
		}
		
		private function stopTimer() : void
		{
		   if ( _timerId != -1 )
		   {
			   clearInterval( _timerId );
			   _timerId = -1;
		   }   
		}
		
		private function onTick() : void
		{
			sendEvent( new Event( SamplePlayerEvent.POSITION_UPDATED ) );
		}	
		
		private function initSound() : void
		{
			_sound = new Sound();
			_sound.addEventListener( Event.OPEN, onOpen, false, 0, true ); 
			_sound.addEventListener( Event.COMPLETE, onComplete, false, 0, true );
			_sound.addEventListener( IOErrorEvent.IO_ERROR, onIOError, false, 0, true );
			_sound.addEventListener( ProgressEvent.PROGRESS, onProgress, false, 0, true );
		}
		
		private function destroySound() : void
		{
			/*_sound.removeEventListener( Event.OPEN, onOpen ); 
			_sound.removeEventListener( Event.COMPLETE, onComplete );
			_sound.removeEventListener( IOErrorEvent.IO_ERROR, onIOError );
			_sound.removeEventListener( ProgressEvent.PROGRESS, onProgress );*/
			
			if ( ( ! _error ) && ( ! isLoaded ) )
			{
				_sound.close();	
			}
			
			_sound = null;
		}	
		
		/**
		 * Запускает процесс воспроизведения семпла с указанным url 
		 * @param url - url семпла
		 * 
		 */		
		public function play( url : String = null, length : Number = NaN ) : void
		{
		    var newFile : Boolean = url != _url;
			
			if ( ! url )
			{
				url = _url;
			}
			
			if ( ( url ) && ( newFile || _error ) )
			{
				_url    = url;
				_length = length;
				
				if ( _sound )
				{
					_stop();
					destroySound();
				}
				
				initSound();
				_sound.load( new URLRequest( url ) );
				
				_channel = _sound.play( 0, 0, _sndTransform );
				_pausePosition = 0.0;
				_playedOneTime = false;
				_opened = false;
				_error = false;
			}	
			else
			{
				if ( _sound == null )
				 throw new Error( 'In this case url must be not null.' );
				
				_channel = _sound.play( _pausePosition, 0, _sndTransform );
			}	
			
			_channel.addEventListener( Event.SOUND_COMPLETE, onSoundComplete );
			sendEvent( new Event( SamplePlayerEvent.START_PLAYING ) );
			setTimer();
		}
		
		private var _pausePosition : Number = 0;
				
		/**
		 * Останавливает процесс воспроизведения текущего семпла 
		 * 
		 */		
		public function stop() : void
		{
		  _stop();	
		}
		
		private function _stop( dispatchEvent : Boolean = true ) : void
		{
			stopTimer();
			
			if ( _channel )
			{
				_pausePosition = 0;
				_channel.stop();
				destroyChannel();
				
				if ( dispatchEvent )
				  sendEvent( new SamplePlayerEvent( SamplePlayerEvent.STOP_PLAYING ) );
			}
		}
		
		public function pause() : void
		{
			stopTimer();
			
			if ( _channel )
			{
				_pausePosition = _channel.position;
				_channel.stop();
				destroyChannel();
				
				sendEvent( new SamplePlayerEvent( SamplePlayerEvent.PAUSE_PLAYING ) );
			}
		}
		
		/**
		 * Громкость воспроизведения. Диапазон значений 0..1 
		 * @return 
		 * 
		 */		
		public function get volume() : Number
		{
			return _sndTransform.volume;
		}	
		
		public function set volume( value : Number ) : void
		{
			_sndTransform.volume = value;
			
			if ( _channel )
			{
				_channel.soundTransform = _sndTransform;
			}
		}
		
		/**
		 * Длительность текущего воспроизводимого семпла в милисекундах 
		 * @return 
		 * 
		 */		
		public function get length() : Number
		{
		  return isNaN( _length ) ? _sound.length : _length;	
		}
		
		/**
		 * Текущая позиция воспроизведения в милисекундах 
		 * @return 
		 * 
		 */		
		public function get position() : Number
		{
			return _channel ? _channel.position : ( _sound ? _pausePosition : 0.0 );
		}
		
		public function set position( value : Number ) : void
		{
			_stop( false );
			_channel = _sound.play( value, 0, _sndTransform );
			_channel.addEventListener( Event.SOUND_COMPLETE, onSoundComplete );
			setTimer();
		}	
		
		/**
		 * текущий воспроизводимый url 
		 * @return 
		 * 
		 */		
		public function get url() : String
		{
			return _url;
		}
		
		public function get error() : Boolean
		{
			return _error;
		}
		
		public function get opened() : Boolean
		{
			return _opened;
		}
		
		/**
		 * Определяет находится ли сейчас плеер в режиме воспроизведения 
		 * @return 
		 * 
		 */		
		public function get isPlaying() : Boolean
		{
			return _channel != null;
		}
		
		/**
		 * Определяет загружен аудио ресурс полностью 
		 * @return 
		 * 
		 */		
		public function get isLoaded() : Boolean
		{
			return _sound ? _sound.bytesLoaded == _sound.bytesTotal : false;
		}
		
		public function get percentLoaded() : Number
		{
			if ( ! _sound ) return 0;
			if ( _sound.bytesTotal == 0 ) return 0;
			return _sound.bytesLoaded / _sound.bytesTotal;
		}	
		
		private function onOpen( e : Event ) : void
		{
			_opened = true;
			sendEvent( e );
		}	
		
		private function onComplete( e : Event ) : void
		{
			sendEvent( e );
		}
		
		private function onIOError( e : IOErrorEvent ) : void
		{
			_error = true;
			sendEvent( e );
		}
		
		private function onProgress( e : ProgressEvent ) : void
		{
			sendEvent( e );
		}
		
		private function onSoundComplete( e : Event ) : void
		{
			stopTimer();
			destroyChannel();
			_playedOneTime = true;
			sendEvent( e );
		}
		
		private function destroyChannel() : void
		{
			_channel.removeEventListener( Event.SOUND_COMPLETE, onSoundComplete );
			_channel = null;
		}
		
		private var clients : Vector.<Client> = new Vector.<Client>();
		
		private function sendEvent( e : Event ) : void
		{
			if ( hasEventListener( e.type ) )
				dispatchEvent( e ); 	
			
			var clients : Vector.<IEventDispatcher> = getClients( _url );
			//trace( 'clients', clients.length, this.clients.length );
			for each( var client : IEventDispatcher in clients )
			 if ( client.hasEventListener( e.type ) )
				client.dispatchEvent( e ); 
		}
		
		private function getClients( url : String ) : Vector.<IEventDispatcher>
		{
			var result : Vector.<IEventDispatcher> = new Vector.<IEventDispatcher>();
			
			for each( var client : Client in clients )
			{
				if ( client.url == url )
				{
					result.push( client.client );
				}
				
				
			}
			
			return result;
		}
		
		public function registerClient( client : IEventDispatcher, url : String ) : void
		{
			clients.push( new Client( client, url ) );
		}
		
		public function unregisterClient( client : IEventDispatcher ) : void
		{
			var i : int = 0;
			
			while( i < clients.length )
			{
				if ( clients[ i ].client == client )
				{
					clients.splice( i, 1 );
					break;
				}
				
				i ++;
			}
		}
	}
}

import flash.events.IEventDispatcher;

class Client
{
	public var client : IEventDispatcher;
	public var url    : String;
	
	public function Client( client : IEventDispatcher, url : String )
	{
		this.client = client;
		this.url = url;
	}
}