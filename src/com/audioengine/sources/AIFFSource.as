/**
 * Значения загрузки 0..10 000 
 */
package com.audioengine.sources
{
	import com.audioengine.format.aiff.AIFFThreadDecoder;
	
	import flash.net.URLRequest;

	public class AIFFSource extends SoundSource
	{
		public function AIFFSource( stream : URLRequest, id : String, bpm : Number, loop : Boolean )
		{
		  super( stream, id, bpm, loop );
		  _encoderClass = AIFFThreadDecoder;
		}	
	}
}