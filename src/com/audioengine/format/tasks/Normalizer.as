package com.audioengine.format.tasks
{
	import com.audioengine.format.EncoderSettings;
	import com.thread.BaseRunnable;
	
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	public class Normalizer extends BaseRunnable implements IEncoder
	{
		private static const bytesPerChunk : int = EncoderSettings.BYTES_PER_CHUNK;
		
		/**
		 * Маскимальное значение в образце 
		 */		
		private var _maxValue : Number = 0.0;
		
		/**
		 * Минимальное значение в образце 
		 */		
		private var _minValue : Number = 0.0;
		
		/**
		 * Коэффициент усиления 
		 */		
		private var _gain     : Number = 1.0;
		
		/**
		 * Данные для обработки 
		 */		
		private var _rawData  : ByteArray;
		
		/**
		 * Текущий статус выполнения 
		 */		
		private var _status : int = EncoderStatus.NONE;
		
		public function Normalizer()
		{
			super();	
		}
		
		public function clear() : void
		{
			
		}
		
		public function calcTotal( rawDataLength : int ) : int
		{
			_total = rawDataLength/* * 2*/;
			return _total;
		}
		
		public function get rawData() : ByteArray
		{
			return _rawData;
		}
		
		public function set rawData( value : ByteArray ) : void
		{
			_rawData = value;
		}
		
		public function get outputData() : ByteArray
		{
			return _rawData;
		}
		
		public function get status() : int
		{
			return _status;
		}
		
		public function get statusString() : String
		{
		  if ( _status == EncoderStatus.ANALYZING )
		  {
			 return 'Нормализация'; //return 'Анализ';
		  }
		  
		  if ( _status == EncoderStatus.NORMALIZING )
		  {
			  return 'Нормализация';
		  }
		  
		  return null;
		}
		
		override public function process() : void
		{
			if ( _status == EncoderStatus.NONE )
			{
				_status = EncoderStatus.ANALYZING;
			}
			
			if ( _status == EncoderStatus.ANALYZING )
			{	
			    analyze();
				return;	
			}
			
			if ( _status == EncoderStatus.NORMALIZING )
			{
				normalize();
				return;
			}	
		}	
		
		private function analyze() : void
		{
			var len : uint = Math.min( _rawData.bytesAvailable, bytesPerChunk );
			var pos : uint = 0;
			var v   : Number;
			
			while( pos < len )
			{
				v = _rawData.readFloat();
				
				_maxValue = Math.max( v, _maxValue );
				_minValue = Math.min( v, _minValue );
				
				pos += 4;
			}
			
			_progress += len;
			
			if ( _rawData.bytesAvailable == 0 )
			{
				_gain = 1 / Math.max( Math.abs( _minValue ),  Math.abs( _maxValue ) );
				
				_status   = EncoderStatus.DONE;//EncoderStatus.NORMALIZING;
				_rawData.position = 0;
			}
		}
		
		private function normalize() : void
		{	
			var len : uint = Math.min( _rawData.bytesAvailable, bytesPerChunk );
			var pos : uint = 0;
			var v   : Number;
			
			while( pos < len )
			{
				v = _rawData.readFloat() * _gain;
				_rawData.position -= 4;
				_rawData.writeFloat( v );
				
				pos += 4;
			}
			
			_progress += len;
			
			if ( _rawData.bytesAvailable == 0 )
			{
				_status   = EncoderStatus.DONE;
				_rawData.position = 0;
			}
		}
		
		public function get maxValue() : Number
		{	
		  return _maxValue;	
		}
		
		public function get minValue() : Number
		{
		  return _minValue;	
		}
		
		public function get gain() : Number
		{
			return _gain;
		}	
	}
}