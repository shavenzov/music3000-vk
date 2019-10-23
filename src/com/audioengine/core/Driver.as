package com.audioengine.core
{
	import com.audioengine.core.events.DriverEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;
    
	/** Dispatched when the currently playing sound has completed. */
	[Event(type="flash.events.SampleDataEvent", name="sampleData")]
	
	public class Driver extends EventDispatcher implements IInput
	{
		/**
		 *The number of samples you provide can vary between 2048 (~46ms) and 8190 (~185ms).  
		 */		
		public static const FRAMES_PER_CALLBACK   : uint = 3072;
		public static const BYTES_PER_CALLBACK    : uint = FRAMES_PER_CALLBACK * AudioData.BYTES_PER_SAMPLE; 
		
		private const _sound: Sound = new Sound();
		private var _soundChannel: SoundChannel;
		
		/**
		 * Девайс подключенный к драйверу 
		 */		
		private var _input : IProcessor;
		
		/**
		 * Задержка между обработками блоков данных 
		 */		
		public var latency : Number = 0.0;
		
		/**
		 * Время обработки данных через подключенный процессор 
		 */		
		public var processTime : Number;
		
		/**
		 * Определяет, работает ли в данный момент аудиодрайвер 
		 */		
		private var _running : Boolean;
		
		/**
		 * Рамера буфера памяти звукового драйвера 
		 */		
		private var _bufferBytesSize : uint;
		
		private const zeroBytes: ByteArray = new ByteArray();
		
		public function Driver( numSamples : uint = FRAMES_PER_CALLBACK )
		{
			_bufferBytesSize = AudioData.framesToBytes( numSamples );
			zeroBytes.length = _bufferBytesSize;
			_sound.addEventListener( SampleDataEvent.SAMPLE_DATA, sampleData );
			_soundChannel = _sound.play();
		}
		
		/**
		 * Девайс подключенный к драйверу 
		 */
		public function get input() : IProcessor
		{
			return _input;
		}
		
		public function set input( value : IProcessor ) : void
		{
			_input = value;
		}
		
		/**
		 *  
		 * @return Текущее значение выборки в левом канале 
		 * 
		 */		
		public function get leftPeak(): Number
		{
			if ( _soundChannel ) return _soundChannel.leftPeak; 	
			
			return 0.0;
		}
		
		/**
		 * Текущее значение выборки в правом канале 
		 * @return 
		 * 
		 */		
		public function get rightPeak(): Number
		{
			if ( _soundChannel ) return _soundChannel.rightPeak;
			
			return 0.0;
		}
		
		/**
		 * Запускает аудиодрайвер 
		 * 
		 */		
		public function run() : void
		{
			if ( ! _input )
			{
				throw new Error( 'Not conected audioprocessor. Set input property first.' );
			}	
			
			if ( _running )
			{
				throw new Error( 'Audio driver already running.' );
			}
			
			_running = true;
		}
		
		/**
		 * Останавливает аудиодрайвер 
		 * 
		 */		
		public function stop() : void
		{
			if ( ! _running )
			{
				throw new Error( 'Audio driver already stopped.' );
			}	
		
			_running = false;
		}
		
		private function sampleData( e: SampleDataEvent ) : void
		{
			if ( _running )
			{
				dispatchEvent( new DriverEvent( DriverEvent.AFTER_PROCESSING ) );
				
				//var now : Number = getTimer();
				/*
				if ( _soundChannel )
				{
					latency = e.position / 44.1 - _soundChannel.position;
				}
				*/
				_input.render( e.data, _bufferBytesSize );
				
				dispatchEvent( new DriverEvent( DriverEvent.BEFORE_PROCESSING ) );
				
				//processTime = getTimer() - now;
				
				//trace( processTime + ' ms' );
			}
			else
			{
				e.data.writeBytes( zeroBytes );
			}
		}
	}
}