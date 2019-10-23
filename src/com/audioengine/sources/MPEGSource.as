/**
 * Значения загрузки 0..10 000 
 */
package com.audioengine.sources
{
	import com.audioengine.format.mpeg.MPEGThreadDecoder;
	
	import flash.net.URLRequest;

	public class MPEGSource extends SoundSource
	{
		public function MPEGSource( stream : URLRequest, id : String, bpm : Number, loop : Boolean )
		{
		  super( stream, id, bpm, loop );
		  _encoderClass = MPEGThreadDecoder;
		}	
	}
}