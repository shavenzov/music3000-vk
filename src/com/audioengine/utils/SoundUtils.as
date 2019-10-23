package com.audioengine.utils
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	import com.audioengine.core.TimeConversion;
	
	import flash.utils.ByteArray;

	public class SoundUtils
	{
		public static function createTestAudioData( duration : Number = 1, _bpm : Number = 140.0 ) : AudioData
		{
			var data   : ByteArray = new ByteArray();
			//Подсчитываем длину в фреймах
			var length : Number = TimeConversion.secondsToNumSamples( duration );
			
			var i : int = 0;
			
			trace( 'totalTestLength : ' + length );
			
			while( i < length )
			{
				data.writeFloat( i );
				data.writeFloat( i );
				i ++;
			}
			
			return new AudioData( 'test', data, _bpm, false );
		}
		
		public static function testAudioData( data : ByteArray ) : void
		{
			var position : uint = data.position;
			var cValue   : Number;
			var b1       : Number;
			var b2       : Number;
			
			data.position = 0;
			
			while( data.position < data.length )
			{
				b1 = data.readFloat();
				b2 = data.readFloat();
				
				//Значения левого и правого канала должны быть равны
				if ( b1 != b2 )
				{
					trace( ( ( data.position - 8 ) / 8 ).toString() + " --> b1 don't equal b2 " + b1 + ',' + b2 );
				}
				
				if ( isNaN( cValue ) ) cValue = b1;
				else
				if ( cValue > b1 )
				{
					trace( ( ( data.position - 8 ) / 8 ).toString() + " --> b1 = " + b1 + " , cValue = " + cValue );
					cValue = b1;
				}
				else
				{
					cValue = b1;
				}	
			}
			
			data.position = position;
		}	
		
		public static function traceByteArray( data : ByteArray ) : void
		{
			var position : uint = data.position;
			
			data.position = 0;
			
			while( data.position < data.length )
			{
				trace( ( data.position / 8 ).toString() + ' --> ' + data.readFloat() + ',' + data.readFloat() );
			}
			
			data.position = position;
		}	
	}
}