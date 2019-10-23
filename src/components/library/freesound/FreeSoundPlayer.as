package components.library.freesound
{
	import classes.SamplePlayer;
	import classes.SamplePlayerImplementation;
	import classes.events.SamplePlayerEvent;
	
	import com.dataloaders.ImageCash;
	import com.utils.TimeUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.IUITextField;
	import mx.core.UIComponent;
	import mx.core.UIFTETextField;
	
	public class FreeSoundPlayer extends UIComponent
	{
		public static const cash : ImageCash = new ImageCash();
		
		private static const WAVEFORM_M_WIDTH  : Number = 120.0;
		private static const WAVEFORM_M_HEIGHT : Number = 71.0;
		
		private var _soundwavePath : String;
		private var _loader : Loader;
		//private var _waveLoadProgress : Shape;
		
		/**
		 * Картинка звуковой волны 
		 */		
		private var _waveform : DisplayObject;
		
		/**
		 * Отображает время 
		 */		
		private var _time : IUITextField;
		
		/**
		 * Затемнение незагрузившейся области 
		 */		
		private var _fade : Shape;
		
		/**
		 * Головка воспроизведения 
		 */		
		private var _playhead : Shape;
		
		/**
		 * Плеер для воспроизведения звука 
		 */		
		private var _player : SamplePlayerImplementation;
		
		/**
		 * Текущий проигрываемый ресурс 
		 */		
		private var _url : String;
		
		/**
		 * Длина звукового образца в миллисекундах 
		 */		
		private var _duration : Number;
		
		/**
		 * Указывает, установлены ли слушатели событий для плеера 
		 */		
		private var _playerInitialized : Boolean;
		
		public function FreeSoundPlayer()
		{
			super();
			_player = SamplePlayer.impl;
			
			addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
		}
		
		public function clear() : void
		{
			_url = null;
			_soundwavePath = null;
			_duration = NaN;
			
			if ( _waveform )
			{
				if ( contains( _waveform ) )
				{
					removeChild( _waveform );
					_waveform = null;
				}	
			}	
			
			if ( _loader )
			{
				releaseSoundwaveListeners();
			}	
			
			releasePlayerListeners();
			
			invalidateProperties();
			invalidateDisplayList();
		}	
		
		private function onRemovedFromStage( e : Event ) : void
		{
			releasePlayerListeners();
		}	
		
		public function get url() : String
		{
			return _url;
		}
		
		public function set url( value : String ) : void
		{
			if ( value != _url )
			{
				_url = value;
				
				if ( _player.url == _url )
				{
					setPlayerListeners();
				}	
			}	
		}
		
		public function get duration() : Number
		{
			return _duration;
		}
		
		public function set duration( value : Number ) : void
		{
			_duration = value;
			invalidateProperties();
		}	
		
		private function setPlayerListeners() : void
		{
		 if ( _playerInitialized ) return;
			
		 _player.addEventListener( Event.COMPLETE, onLoaded );
		 _player.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
		 _player.addEventListener( ProgressEvent.PROGRESS, onProgress );
		 
		 _player.addEventListener( SamplePlayerEvent.POSITION_UPDATED, onPositionUpdated );
		 _player.addEventListener( SamplePlayerEvent.START_PLAYING, onStartPlaying );
		 _player.addEventListener( Event.SOUND_COMPLETE, onSoundComplete );
		 
		 _playerInitialized = true;
		}
		
		private function releasePlayerListeners() : void
		{
		  if ( ! _playerInitialized ) return;	
			
		  _player.removeEventListener( Event.COMPLETE, onLoaded );
		  _player.removeEventListener( IOErrorEvent.IO_ERROR, onIOError );
		  _player.removeEventListener( ProgressEvent.PROGRESS, onProgress );
			
		  _player.removeEventListener( SamplePlayerEvent.POSITION_UPDATED, onPositionUpdated );
		  _player.removeEventListener( SamplePlayerEvent.START_PLAYING, onStartPlaying );
		  _player.removeEventListener( Event.SOUND_COMPLETE, onSoundComplete );
		  
		  _playerInitialized = false;
		}
		
		private function onSoundComplete( e : Event ) : void
		{
			releasePlayerListeners();
			invalidateProperties();
			invalidateDisplayList();
		}	
		
		private function onStartPlaying( e : Event ) : void
		{
			if ( _player.url != _url )
			{
				releasePlayerListeners();
				invalidateProperties();
				invalidateDisplayList();
			}	
		}	
		
		private function onLoaded( e : Event ) : void
		{
			invalidateDisplayList();
		}
		
		private function onIOError( e : IOErrorEvent ) : void
		{
			
		}
		
		private function onProgress( e : ProgressEvent ) : void
		{
			invalidateDisplayList();
		}
		
		private function onPositionUpdated( e  : Event ) : void
		{
			invalidateProperties();
			invalidateDisplayList();
		}	
		
		private function releaseSoundwaveListeners() : void
		{
			_loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, onLoadWaveComplete );
			//_loader.contentLoaderInfo.removeEventListener( ProgressEvent.PROGRESS, onLoadWaveProgress ); 
			_loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, onLoadWaveIOError );
			
			_loader = null;
		}
		
		private function setSoundwaveListeners() : void
		{
			_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoadWaveComplete );
			//_loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, onLoadWaveProgress ); 
			_loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onLoadWaveIOError );
		}
		
		private function onLoadWaveComplete( e : Event ) : void
		{
			setWaveform( _loader.content );
			releaseSoundwaveListeners();
			
			invalidateDisplayList();
		}
		
		private function onLoadWaveProgress( e : ProgressEvent ) : void
		{
			invalidateDisplayList();
		}
		
		private function onLoadWaveIOError( e : IOErrorEvent ) : void
		{
			releaseSoundwaveListeners();
			
			invalidateDisplayList();
		}	
		
		public function get soundwavePath() : String
		{
			return _soundwavePath;
		}
		
		public function set soundwavePath( path : String ) : void
		{
			if ( path != _soundwavePath )
			{
				_soundwavePath = path;
				
				if ( _loader )
				{
					releaseSoundwaveListeners();
				}
				
				var loader : Loader = cash.getImage( _soundwavePath );
				
				if ( loader.content )
				{
					setWaveform( loader.content );
				}
				else
				{
					_loader = loader;
					setSoundwaveListeners();
				}	
			}	
		}		
		
		private function setWaveform( value : DisplayObject ) : void
		{
			if ( _waveform != value )
			{
				
				if ( ( _waveform != null ) && ( contains( _waveform ) ) )
				{
					removeChild( _waveform );
				}
				
				//Делаем прозрачным задний фон звуковой волны
				var bitmap : BitmapData = new BitmapData( value.width, value.height );
				bitmap.threshold( Bitmap( value ).bitmapData, new Rectangle( 0,0, value.width, value.height ),
					                                          new Point( 0.0, 0.0 ), '==', 0xff000000, 0x00000000, 0xFFFFFFFF, true );
					
				_waveform = new Bitmap( bitmap );
				
				addChildAt( _waveform, 0 );
			}	  
		}	
		
		override protected function createChildren():void
		{
			super.createChildren();
			/*
			_waveLoadProgress = new Shape();
			_waveLoadProgress.graphics.beginFill( 0x00ff00, 0.85 );
			_waveLoadProgress.graphics.drawRect( 0.0, 0.0, 10.0, 8.0 );
			_waveLoadProgress.graphics.endFill();
			_waveLoadProgress.visible = false;
			*/
			_fade = new Shape();
			_fade.graphics.beginFill( 0x000000, 0.5 );
			_fade.graphics.drawRect( 0.0, 0.0, 10.0, 10.0 );
			_fade.graphics.endFill();
			_fade.visible = false;
			
			_playhead = new Shape();
			_playhead.graphics.beginFill( 0xffffff, 0.9 );
			_playhead.graphics.drawRect( 0.0, 0.0, 2.0, WAVEFORM_M_HEIGHT );
			_playhead.graphics.endFill();
			_playhead.visible = false
				
			_time = IUITextField( createInFontContext( UIFTETextField ) );
			_time.filters = [ new GlowFilter( 0x000000, 1.0, 3.0, 3.0 ) ];
			_time.visible = false;
			
			//addChild( _waveLoadProgress );
			addChild( _fade );
			addChild( _playhead );
			addChild( _time );
			
			addEventListener( MouseEvent.CLICK, onClick );
		}
		
		private function onClick( e : MouseEvent ) : void
		{
		  if ( _playerInitialized )
		   {
			if ( _player.isPlaying )
			 {
				_player.stop();
			  }
			  else
			  {
			  _player.play();
			  }	
			 }
			 else
			  {
				 setPlayerListeners();
				 _player.play( _url, _duration );
			  }	
		}	
		
		override protected function measure() : void
		{
			super.measure();
			
			measuredWidth  = WAVEFORM_M_WIDTH;
			measuredHeight = WAVEFORM_M_HEIGHT;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( ! isNaN( _duration ) )
			{
				if ( _playerInitialized && _player.isPlaying )
				{
					_time.text = TimeUtils.formatMiliseconds( _player.position );
				}	
				else
				{
					_time.text = TimeUtils.formatMiliseconds( _duration );
				}
			}	
		}	
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			/*
			if ( _loader )
			{
				_waveLoadProgress.visible = true;
				_waveLoadProgress.x      = 0;
				_waveLoadProgress.width  = unscaledWidth * ( _loader.contentLoaderInfo.bytesLoaded / _loader.contentLoaderInfo.bytesTotal );
			}
			else
			{
              _waveLoadProgress.visible = false;
			}	
			*/
				if ( _playerInitialized && ! _player.isLoaded )
				{
					_fade.visible = true;
					
					_fade.x      = unscaledWidth * _player.percentLoaded;
					_fade.width  = unscaledWidth - _fade.x;
					_fade.height = unscaledHeight;
				}
				else
				{
					_fade.visible = false;	
				}
				
				if ( _playerInitialized && _player.position != 0 )
				{
					_playhead.visible = true;
					_playhead.x = ( _player.position * unscaledWidth ) / _duration;
				}
				else
				{
					_playhead.visible = false;	
				}
				
				if ( isNaN( _duration ) )
				{
					_time.visible = false;	
				}
				else
				{
					_time.visible = true;
					
					_time.setActualSize( _time.getExplicitOrMeasuredWidth(), _time.getExplicitOrMeasuredHeight() );
					_time.x = unscaledWidth - _time.width;
					_time.y = unscaledHeight - _time.height;
				}	
		}	
	}
}