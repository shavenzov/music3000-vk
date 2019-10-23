package com.audioengine.devices
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.Driver;
	import com.audioengine.core.IAudioData;
	import com.audioengine.core.IProcessor;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.core.events.AudioDataEvent;
	import com.audioengine.utils.SoundUtils;
	
	import flash.events.ActivityEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	public class AudioInput extends EventDispatcher implements IProcessor
	{
		public static const MUTED   : String = 'Microphone.Muted';
		public static const UNMUTED : String = 'Microphone.Unmuted';
		
		/**
		 * Перенаправлять ли звук с микрофона в колонки
		 */		
		private var _loopBack : Boolean;
		
		/**
		 * Коэффициент усиления сигнала 
		 */		
		//private var _gain : Number = 9.5;
		
		/**
		 * Буфер для записи данных с микрофона
		 */		
		private var data : IAudioData;
		
		/**
		 * Идет ли процесс записи в настоящий момент или нет 
		 */		
		private var _isRecording : Boolean;
		
		/**
		 * Ссылка на аудио вход
		 */		
		private var _mic : Microphone;
		
		/**
		 * Указывает что идет процесс синхронизации 
		 */		
		private var _synchronization : Boolean;
		/**
		 * Начинать запись в буфер при с нуля при следующем обновлении  
		 */		
		private var _reset : Boolean;
		
		/**
		 * Размер буфера линии
		 */		
		private var _outputDataSize : int = -1;
		
		/**
		 * Размер буфера синхронизации 
		 */		
		private var _bufferSize : int = -1;
		
		/**
		 * Количество буферов синхронизации 
		 */		
		private const _outNumBuffers : int = 4;
		
		/**
		 * Текущий индекс выходного буфера 
		 */		
		private var _outBufferIndex : int;
		
		/**
		 *  Буфер для кеширования
		 */		
		private var _buffer : ByteArray = new ByteArray();
		
		/**
		 * Нулевые данные 
		 */		
		private const zeroBytes: ByteArray = new ByteArray();
		
		public function AudioInput( deviceIndex : int = -1 )
		{
		  super();
		  prepare( deviceIndex );
		}
		
		private function prepare( deviceIndex : int ) : void
		{
			_mic = Microphone.getMicrophone( deviceIndex );
			
			if ( _mic )
			{	
				_mic.rate = 44;
				_mic.gain = 50.0;
				_mic.setSilenceLevel( 0.0 );
				_synchronization = true;
				
				_mic.addEventListener( SampleDataEvent.SAMPLE_DATA, onSampleEvent );
				_mic.addEventListener( StatusEvent.STATUS, onStatus );
			}
			else
			{
				throw new Error( 'Not found audio input with index ' + deviceIndex );
			}	
		}	
		
		private function onStatus( e : StatusEvent ) : void
		{
			dispatchEvent( e );
		}	
		
		public function dispose() : void
		{
			_mic.removeEventListener( StatusEvent.STATUS, onStatus );
			_mic.removeEventListener( SampleDataEvent.SAMPLE_DATA, onSampleEvent );
			
			_mic.setLoopBack( false );
			_mic = null;
		}	
		
		private var sample   : Number;
		/**
		 * Максимальное значение выборки сигнала во время записи 
		 */		
		private var dMinValue : Number = NaN;
		private var minValue  : Number = NaN;
		private var lastValue : Number = 0.0;
		private var dV : Number;
		
		private function onSampleEvent( e : SampleDataEvent ) : void
		{		
			if ( _isRecording && isNaN( _emptyBytes ) )
			{
				//Определяем задержку между записью и воспроизведением
				_emptyBytes = AudioData.framesToBytes( TimeConversion.milisecondToNumSamples( getTimer() - _synchroTime ) ) + e.data.length << 1 + Driver.BYTES_PER_CALLBACK;
			}
			
			if ( _reset )
			{
				_buffer.position = 0;
				_reset = false;
			}	
			
			while( e.data.bytesAvailable > 0 )
			{
				sample = e.data.readFloat();
				
				//Определяем уровень шума сигнала (минимальный уровент сигнала) и корректируем выборку, для предотвращения щелчков
				dV = Math.abs( lastValue - sample );
				
				if ( isNaN( minValue ) )
				{
					dMinValue = dV;
					minValue  = sample;
				}	
				else
				{	
					if ( dMinValue > dV )
					{
						dMinValue = dV;
						minValue = sample;
					}	
				}
				
				lastValue = sample;
				sample   -= minValue;
					
				if ( _isRecording )
				{
					data.data.writeFloat( sample );
					data.data.writeFloat( sample );
				}
					
				if ( _bufferSize > 0 )
				{
					_buffer.writeFloat( sample );
					_buffer.writeFloat( sample );
					
					if ( _buffer.position == _bufferSize )
					{	
						_buffer.position = 0;
					}
				}	
			}
			
			if ( _synchronization )
			{
				if ( _buffer.position >= _outputDataSize << 1 )
				{	
					_synchronization = false;
				}
			}
			
			if ( _isRecording )
			{	
				data.dispatchEvent( new Event( Event.CHANGE ) );	
			}
		}	
		
		/**
		 * Запускает процесс записи данных в буфер 
		 * 
		 */		
		public function start( data : IAudioData ) : void
		{
			if ( _isRecording )
			{	
				throw new Error( 'AudioInput have already in record mode.' );
			}
			
			this.data = data;
			
			_emptyBytes = NaN;
			_isRecording  = true;
			_synchroTime = getTimer();
		}
		
		/**
		 * Останавливает процесс записи данных в буфер 
		 * 
		 */		
		public function stop() : void
		{
			if ( ! _isRecording )
			{
				throw new Error( "AudioInput not in record mode. Call start first." );
			}
			
			_isRecording  = false;
			
			//Убираем необходимое количество данных в начале
			var b : ByteArray = new ByteArray();
			   
			b.writeBytes( data.data, _emptyBytes );
			data.data.position = 0;
			data.data.writeBytes( b );
			data.data.length = b.length;
			
			data.dispatchEvent( new Event( Event.CHANGE ) );
			
			data = null;
		}
		
		/**
		 * Определяет доступен ли этот канал или нет 
		 * @return 
		 * 
		 */		
		public function get muted() : Boolean
		{
			return ( _mic == null ) || _mic.muted;
		}	
		
		/**
		 * Коэффициент усиления звука с микрофона 0..100
		 * 
		 */		
		public function get gain() : Number
		{
			return _mic.gain;
		}
		
		public function set gain( value : Number ) : void
		{	
			_mic.gain = value;
		}
		
		/**
		 * Перенаправлять ли звук с микрофона в колонки
		 */ 
		public function get loopBack() : Boolean
		{
			return _loopBack;
		}
		
		public function set loopBack( value : Boolean ) : void
		{
		  if ( value != _loopBack )
		  {	   
			  _loopBack = value;
			  _mic.setLoopBack( _loopBack );
			  _mic.setUseEchoSuppression( _loopBack );  
		  }
		}	
		
		public function get isRecording() : Boolean
		{	
			return _isRecording;
		}
		
		/**
		 * Сколько байтов необходимо вырезать в начале для синхронизации записи с воспроизведением 
		 */		
		private var _emptyBytes : Number;
		
		/**
		 * Время вызова метода start 
		 */		
		private var _synchroTime : Number;
			
		public function render( data : ByteArray, bytes : uint ) : void
		{	
			if ( bytes != _outputDataSize )
			{
				_outputDataSize = bytes;
				_bufferSize = _outputDataSize * _outNumBuffers;
				_outBufferIndex = 0;
				_reset = true;
				_synchronization = true;
			}	
			
			if ( _synchronization )
			{
				zeroBytes.length = bytes;
				data.writeBytes( _buffer );
				return;
			}	
			
			var pos    : Number = _outBufferIndex * _outputDataSize;
			var offset : Number;
			
			if ( pos > _buffer.position )
			{	
				offset = _buffer.position  + ( _bufferSize - pos );
			}
			else
			{
				offset = _buffer.position - pos;
			}	
			
			data.writeBytes( _buffer, pos, _outputDataSize );
			
			_outBufferIndex ++;
			
			if ( _outBufferIndex == _outNumBuffers )
			{
				_outBufferIndex = 0;
			}
		}
		
		/**
		 * Определяет поддерживается ли запись с микрофона на этом устойстве 
		 * @return 
		 * 
		 */		
		public static function get isSuported() : Boolean
		{
			return Microphone.isSupported;
		}	
	}
}