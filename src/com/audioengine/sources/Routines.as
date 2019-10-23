package com.audioengine.sources
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.sequencer.AudioLoop;
	
	import flash.utils.ByteArray;
	
	public class Routines
	{
		private static const CEIL_FACTOR : Number = 0.9/*5*/;
		
		/**
		 * Если остаток количества ударов в "петле" больше CEIL_FACTOR, то добавляет несколько выборок, до целого значения   
		 * @param data
		 * @param bpm
		 * 
		 * Возвращает количество добавленных выборок
		 * 
		 */		
		public static function ceilLoop( data : ByteArray, bpm : Number ) : Number
		{
			var len  : int = AudioData.bytesToFrames( data.length );
			var bits : Number = len / TimeConversion.bitsToNumSamples( 1.0, bpm );
			var a    : Number = bits - Math.floor( bits );
			trace( 'a = ', a );
			if ( a >= CEIL_FACTOR )
			{	
				var newLen : int = Math.ceil( TimeConversion.bitsToNumSamples( Math.ceil( bits ), bpm ) );
				var i      : int = len;
				
				while( i < newLen )
				{
					data.writeFloat( 0.0 );
					data.writeFloat( 0.0 );
					
					i ++;
				}
				
				return newLen - len;
			}
			
			return 0.0;
		}
		
		/**
		 * Если остаток количества ударов в "петле" больше CEIL_FACTOR, то увеличивает значение длины, чтобы умещалось целое количество ударов  
		 * @param length
		 * @param bpm
		 * 
		 */		
		public static function ceilLength( length : Number, bpm : Number ) : Number
		{	
			var bits : Number = length / TimeConversion.bitsToNumSamples( 1.0, bpm );
			var a    : Number = bits - Math.floor( bits );
			
			if ( a >= CEIL_FACTOR )
			{	
				return Math.ceil( TimeConversion.bitsToNumSamples( Math.ceil( bits ), bpm ) );	
			}
			
			return length;
		}
		
		/**
		 * Уменьшаем длину до целого количества ударов в семпле  
		 * @param length
		 * @param bpm
		 * 
		 */	
		public static function floorLength( length : Number, bpm : Number ) : Number
		{
			//Количество ударов в семпле
			var bits : Number = length / TimeConversion.bitsToNumSamples( 1.0, bpm );
			var holeBits : Number = Math.floor( bits ); //Количество целых ударов в семпле		 
			return Math.floor( TimeConversion.bitsToNumSamples( holeBits, bpm ) );
		}	
	}
}