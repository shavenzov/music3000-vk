/**
 * Буфер всегда предполагает, что данные находятся в формате 44100 khz, 16 bit, Stereo 
 */
package com.audioengine.core
{
	import com.audioengine.calculations.Calculation;
	import com.audioengine.calculations.Invert;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;

	public class AudioData extends EventDispatcher implements IAudioData
	{
		private var _locked : Boolean;
		
		/**
		 * Частота дискретизации по умолчанию 
		 */		
		public static const RATE : Number = 44100.0;
		
		/**
		 * Байт в одном канале 
		 */		
		public static const BYTES_PER_CHANNEL : int = 4;
		
		/**
		 * Байт в одной выборке 
		 */		
		public static const BYTES_PER_SAMPLE : int = 8;
		
		/**
		 * Идентификатор семпла в палитре 
		 */		
		private var _id : String;
		
		/**
		 * Информация о расположении в памяти данных семпла 
		 */		
		private var _data : ByteArray;
		
		/**
		 * Количество ударов в секунду 
		 */		
		private var _bpm : Number;
		
		/**
		 * Является ли образец петлей 
		 */		
		private var _loop : Boolean;
		
		/**
		 * Количество выборок добавленных загрузчиком для выравнивания до целого числа ударов 
		 */		
		private var _loaderAddition : Number;
		
		/**
		 * Максимальное значение выборки в data 
		 */		
		//private var _maxValue : Number = 2.0;
		
		public function AudioData( id : String, data : * = null, bpm : Number = 140.0, loop : Boolean = true, loaderAddition : Number = 0.0 )
		{
			if ( data == null )
			{
				_data = new ByteArray();
			}	
			else
			if ( data as Number )
			{
				_data   = new ByteArray();
				_data.length = framesToBytes( Number( data ) );
			}
			else if ( data as ByteArray )
			{	
				_data = data;
			}
			
			_id   = id;
			_bpm  = bpm;
			_loop = loop;
			_loaderAddition = loaderAddition;
		}	
		
		/**
		 * Количество выборок добавленных загрузчиком для выравнивания до целого числа ударов 
		 */
		public function get loaderAddition() : Number
		{
			return _loaderAddition;
		}
		
		public function get id() : String
		{
			return _id;
		}	
		
		public function get loop() : Boolean
		{
			return _loop;
		}	
		
		public function get bpm() : Number
		{
			return _bpm;
		}	
		
		public function get locked() : Boolean
		{
			return _locked;
		}
		
		public function set locked( value : Boolean ) : void
		{
			_locked = value;
		}	
		
		/**
		 * @return Количество выборок в  буфере  
		 * 
		 */		
		public function get length() : Number
		{
			return bytesToFrames( _data.length );
		}
		
		/**
		 * Длина данных в секундах 
		 * @return 
		 * 
		 */		
		public function get timeLength() : Number
		{
			return TimeConversion.numSamplesToSeconds( length );
		}	
		
		//Копирует данные слева на право
		private function copyLeftToRight( buffer : ByteArray, srcOffset : Number, dstOffset : Number, length : Number ) : void
		{
			buffer.position = framesToBytes( dstOffset );
			buffer.writeBytes( _data, framesToBytes( srcOffset ), framesToBytes( length ) );
		}
		
		/**
		 * Инвертор для варианта копирования данных справа на лево 
		 */		
		private var invertor : Invert;
		private var subBuffer : ByteArray;
		private var result    : ByteArray;
		
		//Копирует данные справа на лево
		private function copyRightToLeft( buffer : ByteArray, srcOffset : Number, dstOffset : Number, length : Number ) : void
		{
			srcOffset = this.length - srcOffset - length;
			
			if ( ! subBuffer )
			{
				subBuffer = new ByteArray();
				result    = new ByteArray();
				invertor  = new Invert();
			}
			
			buffer.position = AudioData.framesToBytes( dstOffset );
			
			var pos : int = 0;
			var cl  : int;
			
			while( pos < length )
			{
				cl = Math.min( Calculation.MAX_DATA_WIDTH, length - pos );
				copyLeftToRight( subBuffer, ( srcOffset + length ) - cl - pos, 0, cl );
				
				invertor.length = cl;
				invertor.input = subBuffer;
				invertor.calculate( result );
				
				buffer.writeBytes( result );
				
				pos += cl;
			}
			
			subBuffer.length = 0;
			result.length = 0;
		}
		
		/**
		 * Копирует данные в указанный буфер с указанной позиции указанной длинны 
		 * @param buffer буфер в который будет произведено копировани
		 * @param srcOffset индекс с которого будет поисходить копирование из источника
		 * @param dstOffset индекс с которого будет поисходить копирование в приемник 
		 * @param length длина копируемых данных
		 * 
		 */		
		public function copy( buffer : ByteArray, srcOffset : Number, dstOffset : Number, length : Number, params : Object = null ) : void
		{
			//trace( 'audioData', srcOffset, length, srcOffset + length, this.length );
			
			if ( params && Boolean( params ) )
			{
			  copyRightToLeft( buffer, srcOffset, dstOffset, length );
			  return;
			}
			
			copyLeftToRight( buffer, srcOffset, dstOffset, length );
		}
		
		/**
		 * Обнуляет буфер с указанной позиции указанной длины 
		 * @param index позиция с которой будет происходит очищение
		 * @param length количество выборок которые будут подвергнуты очищению
		 * 
		 */		
		/*
		public function clear() : void
		{
	      _data = new ByteArray();
		  _data.length = framesToBytes( _length );
		}
		*/
		
		/**
		 * Информация о расположении в памяти данных семпла 
		 */
		public function get data() : ByteArray
		{
			return _data;
		}
		
		/**
		 *  @return Возвращает клон объекта 
		 * 
		 */		
		public function clone() : IAudioData
		{
			var d : AudioData = new AudioData( _id, length, _bpm, _loop );
			    copy( d.data, 0, 0, length );
				
			return d;	
		}
		
		/**
		 * Преобразует количество выборок, в необходимое количество байт 
		 * @param frames количество выборок
		 * @return количество байт
		 * 
		 */		
		public static function framesToBytes( frames : Number ) : Number
		{
			return frames * BYTES_PER_SAMPLE;
		}
		
		/**
		 * Преобразует количество бит, в необходимое количество байт 
		 * @param bytes количество байт
		 * @return количество выборок
		 * 
		 */		
		public static function bytesToFrames( bytes : Number ) : Number
		{
			return bytes / BYTES_PER_SAMPLE;
		}
		
		public function dispose() : void
		{
			if ( _data )
			{
				_data.clear();
			}
		}	
	}
}