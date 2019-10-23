/**
 * Реализует "Пустышку" аудио данных, т.е. при вызове copy всегда возвращает буфер заполненный нулями
 * Необходим, в качестве заменителя данных на время загрузки данных 
 */
package com.audioengine.core
{
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;

	public class DummyAudioData extends EventDispatcher implements IAudioData
	{
		/**
		 * Идентификатор семпла в палитре 
		 */		
		private var _id : String;
		
		/**
		 * Количество ударов в секунду 
		 */		
		private var _bpm : Number;
		
		/**
		 * Является ли образец петлей 
		 */		
		private var _loop : Boolean;
		
		/**
		 * Размер данных в фреймах 
		 */		
		private var _length : Number;
		
		/**
		 * Нулевые данные, минимальная длина 
		 */		
		private var _data : ByteArray;  
		
		public function DummyAudioData( id : String, length : Number, bpm : Number = 140.0, loop : Boolean = true )
		{
		  super();
		  
		  _data = new ByteArray();
		  
		  _id     = id;
		  _bpm    = bpm;
		  _loop   = loop;
		  _length = length;
		}
		
		public function get id() : String
		{
			return _id;
		}
		
		public function get loaderAddition() : Number
		{
			return 0.0;
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
			return true;
		}
		
		public function set locked( value : Boolean ) : void
		{
		}
			
		public function copy( buffer : ByteArray, srcOffset : Number, dstOffset : Number, length : Number, params : Object = null ) : void
		{
			var lengthInBytes : Number = AudioData.framesToBytes( length );
			
			if ( _data.length < lengthInBytes )
			{
				_data.length = lengthInBytes;
			}	
			
			buffer.position = AudioData.framesToBytes( dstOffset );
			buffer.writeBytes( _data, 0, lengthInBytes );
		}
		
		/**
		 * Информация о расположении в памяти данных семпла 
		 */
		public function get data() : ByteArray
		{
			var b : ByteArray = new ByteArray();
			    b.length = AudioData.framesToBytes( _length );
			
			return b;
		}
		
		/**
		 *  @return Возвращает клон объекта 
		 * 
		 */		
		public function clone() : IAudioData
		{
			return new DummyAudioData( _id, _length, _bpm, _loop );	
		}
		
		/**
		 * @return Количество выборок в  буфере  
		 * 
		 */		
		public function get length() : Number
		{
			return _length;
		}
		
		public function dispose() : void
		{
			
		}
	}
}