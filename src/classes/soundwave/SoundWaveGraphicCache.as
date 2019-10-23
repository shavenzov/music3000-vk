package classes.soundwave
{
	import com.audioengine.core.IAudioData;
	import com.audioengine.core.TimeConversion;
	import com.thread.IRunnable;
	import com.thread.SequencedThread;
	
	import flash.events.Event;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	public class SoundWaveGraphicCache
	{
		/**
		 * После вызова метода UPDATE, поток перерисовки будет выполнен, только после этого интервала времени 
		 */		
		private static const UPDATE_TIME : Number = 250.0;
		
		private static const INVERT_PREFIX : String = 'invert';
		private static const CONST_PREFIX  : String = 'const';
		private static const ID_SEPARATOR  : String = '_';
		
		private var _waves : Vector.<ISoundWaveGraphic> = new Vector.<ISoundWaveGraphic>();
		private var _height : Number = Settings.TRACK_HEIGHT;
		
		private var _thread : SequencedThread;
		
		private var _timer_id : int = -1;
		
		private var _bpm   : Number;
		private var _scale : Number;
		
		public function SoundWaveGraphicCache()
		{
		  super();
		}
		
		private function createId( id : String, constant : Boolean, invert : Boolean) : String
		{
			if ( constant )
			{
				id += ID_SEPARATOR + CONST_PREFIX;
			}
			
			if ( invert )
			{
				id += ID_SEPARATOR + INVERT_PREFIX;
			}
			
			return id;
		}	
		
		/**
		 * Создает стандартный график волны 
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createW( id : String, data : IAudioData ) : String
		{
			_waves.push( new SoundWaveGraphic( data, id, true, true ) );
			
			return id;
		}
		
		/**
		 * Создает стандартный график волны, если его не существует 
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createWIfNotExists( id : String, data : IAudioData ) : String
		{
			if ( ! getW( id ) ) 
			{
				_waves.push( new SoundWaveGraphic( data, id, true, true ) );
			}
			
			return id;
		}	
		
		/**
		 * Создаем график волны не перерисовываемый при изменении масштаба 
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createConstW( id : String, data : IAudioData ) : String
		{	
			id = createId( id, true, false );
			
			_waves.push( new SoundWaveGraphic( data, id, true, false) );
			
			return id;
		}
		
		/**
		 * Создаем график волны не перерисовываемый при изменении масштаба, если его не существует 
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createConstWIfNotExists( id : String, data : IAudioData ) : String
		{	
			id = createId( id, true, false );
			
			if ( ! getW( id ) )
			{
				_waves.push( new SoundWaveGraphic( data, id, true, false ) );
			}	
			
			return id;
		}
		
		/**
		 * Создает простой инвертированный график волны 
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createInvertedW( id : String, data : IAudioData ) : String
		{
			id = createId( id, false, true );
			
			_waves.push( new InvertedSoundWaveGraphic( data, id, true, true ) );
			
			return id;
		}
		
		/**
		 * Создает простой инвертированный график волны, если его не существует 
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createInvertedWIfNotExists( id : String, data : IAudioData ) : String
		{
			id = createId( id, false, true );
			
			if ( ! getW( id ) )
			{
				_waves.push( new InvertedSoundWaveGraphic( data, id, true, true ) );
			}	
			
			return id;
		}
		
		/**
		 * Создает инвертированный график волны не перерисовываемый при изменении масштаба
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createConstAndInvertedW( id : String, data : IAudioData ) : String
		{
			id = createId( id, true, true );
			
			_waves.push( new InvertedSoundWaveGraphic( data, id, true, false ) );
			return id;
		}
		
		/**
		 * Создает инвертированный график волны не перерисовываемый при изменении масштаба, если его не существует 
		 * @param id
		 * @param data
		 * @return 
		 * 
		 */		
		public function createConstAndInvertedWIfNotExists( id : String, data : IAudioData ) : String
		{
			id = createId( id, true, true );
			
			if ( ! getW( id ) )
			{
				_waves.push( new InvertedSoundWaveGraphic( data, id, true, false ) );	
			}
			return id;
		}
		
		/**
		 * Возвращает wave с указанным идентификатором и увеличивает количество объектов ссылающихся на него 
		 * @param id
		 * @return 
		 * 
		 */		
		public function attachW( id : String ) : ISoundWaveGraphic
		{
			var wave : ISoundWaveGraphic = getW( id );
			
			if ( wave )
			{
				wave.attach();
			}	
			
			return wave;
		}
		
		public function detachW( id : String ) : void
		{
			var waveIndex : int = getWIndex( id );
			
			if ( waveIndex != -1 )
			{
				var wave : ISoundWaveGraphic = _waves[ waveIndex ];
				
				wave.dettach();
				
				if ( wave.links == 0 )
				{
					removeWByIndex( waveIndex );
				}	
			}
		}	
		
		/**
		 * Полностью удаляет wave с указанным идентификатором 
		 * @param id
		 * 
		 */		
		public function removeW( id : String ) : void
		{
			var i : int = 0;
			
			while( i < _waves.length )
			{
				if ( _waves[ i ].id == id )
				{
					removeWByIndex( i );
					return;
				}	
				
				i ++;
			}	
		}
		
		/**
		 * Полностью удаляет wave с указанным идентификатором 
		 * @param id
		 * 
		 */		
		private function removeWByIndex( index : int ) : void
		{
			_waves[ index ].clear();
			_waves.splice( index, 1 );	
		}
		
		/**
		 * Возвращает wave с указанным идентификатором или null, если такого не найдено 
		 * @param id
		 * @return 
		 * 
		 */		
		public function getW( id : String ) : ISoundWaveGraphic
		{
			var i : int = 0;
			
			while( i < _waves.length )
			{
				if ( _waves[ i ].id == id )
				{
					return _waves[ i ];
				}	
				
				i ++;
			}
			
			return null;
		}
		
		/**
		 * Возвращает индекс wave с указанным идентификатором или -1, если такого не найдено 
		 * @param id
		 * @return 
		 * 
		 */		
		private function getWIndex( id : String ) : int
		{
			var i : int = 0;
			
			while( i < _waves.length )
			{
				if ( _waves[ i ].id == id )
				{
					return i;
				}	
				
				i ++;
			}
			
			return -1;
		}
		
		public function updateWById( id : String, updateNow : Boolean = true ) : void
		{
			var wave : ISoundWaveGraphic = getW( id );
			
			if ( wave )
			{
				updateW( wave, updateNow );
			}
			else throw new Error( "Can't find wave with id = " + id + "." );
		}	
		
		public function updateW( wave : ISoundWaveGraphic, updateNow : Boolean = true ) : void
		{	
			if ( wave.bpmChange && wave.scaleChange )
			{
				var k    : Number = TimeConversion.scaleFactor( wave.data.bpm, _bpm );
				wave.w = Math.ceil( ( wave.data.length * k ) / _scale );
			}	
			else if ( wave.scaleChange )
			{
				wave.w = Math.ceil( wave.data.length / _scale );
			}
			else if ( wave.bpmChange )
			{
				
			}	
		
			wave.h = _height;
			
			if ( updateNow )
			{
				if ( ! wave.rendering && ! wave.locked )
				{
					wave.updateChangedData();
				}	
			}
		}
		
		private function setUpdateInterval() : void
		{
			if ( _timer_id == -1 )
			{
				_timer_id = setTimeout( commitUpdate, UPDATE_TIME );
			}	 		
		}
		
		private function clearUpdateInterval() : void
		{
			if ( _timer_id != -1 )
			{
				clearTimeout( _timer_id );
				_timer_id = -1;
			}	
		}
		
		/**
		 * Перерисовывает звуковые волны 
		 * @param _scale
		 * @param _bpm
		 * 
		 */		
		public function update( scale : Number, bpm : Number, updateNow : Boolean = false ) : void
		{
		  var scaleChanged : Boolean = _scale != scale;
		  var bpmChanged   : Boolean = _bpm != bpm;
			
		  _scale = scale;
		  _bpm   = bpm;
			
		  if ( _waves.length == 0 ) return;
		  
		  clearUpdate();
		  clearUpdateInterval();
		  
		  if ( updateNow )
		  {
			  markAsNeedUpdate( scaleChanged, bpmChanged );
			  commitUpdate();
		  }
		  else
		  {
			 markAsNeedUpdate( scaleChanged, bpmChanged );
			 setUpdateInterval(); 
		  }	  
		}
		
		private function markAsNeedUpdate( scaleChanged : Boolean, bpmChanged : Boolean ) : void
		{
			var i : int = 0;
			var wave : ISoundWaveGraphic;
			
			while( i < _waves.length )
			{
				wave            = _waves[ i ];
				
				if ( ! wave.needUpdate )
				{
					wave.needUpdate = ( scaleChanged && wave.scaleChange ) || ( bpmChanged && wave.bpmChange );
					wave.locked     = true;
				}	
				
				i ++;
			}	
		}	
		
		private function clearUpdate() : void
		{
			//Отменяем предыдущий поток, если он еще не выполнен
			if ( _thread )
			{
				_thread.destroy();
				onTasksCompleted( null );
			}	
		}	
		
		public function commitUpdate() : void
		{
		    clearUpdate();
			
			var i     : int = 0;
			var tasks : Vector.<IRunnable> = new Vector.<IRunnable>();
			
			while( i < _waves.length )
			{
				var wave : ISoundWaveGraphic = _waves[ i ];
				
				if ( wave.needUpdate )
				{
					updateW( wave, false );
					
					if ( wave.w > 0 )
					{
						tasks.push( new SoundWaveUpdater( wave ) );
					}	
				}	
				
				i ++;
			}
			
			_thread = new SequencedThread( tasks, 40.0 );
			_thread.addEventListener( Event.COMPLETE, onTasksCompleted );
			_thread.start();
		}	
		
		private function onTasksCompleted( e : Event ) :void
		{
			_thread.removeEventListener( Event.COMPLETE, onTasksCompleted );
			_thread = null;
		}
		
		/**
		 * Удаляет все графики звуковых волн 
		 * 
		 */		
		public function clear() : void
		{
			clearUpdate();
			clearUpdateInterval();
			
			for each( var w : ISoundWaveGraphic in _waves )
			 w.clear();
			 
			_waves.length = 0; 
		}	
	}
}