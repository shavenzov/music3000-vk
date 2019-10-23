/**
 * Значения загрузки 0..10 000 
 */
package com.audioengine.sources
{
	import com.audioengine.format.wav.WAVEThreadDecoder;
	
	import flash.net.URLRequest;

	public class WAVESource extends SoundSource
	{
		public function WAVESource( stream : URLRequest, id : String, bpm : Number, loop : Boolean )
		{
		  super( stream, id, bpm, loop );
		  _encoderClass = WAVEThreadDecoder;
		}	
	}
}