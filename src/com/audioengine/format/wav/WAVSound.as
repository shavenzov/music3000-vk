package com.audioengine.format.wav
{
	import com.audioengine.format.pcm.PCMSound;

	import flash.utils.ByteArray;
	
	public final class WAVSound extends PCMSound
	{
		public function WAVSound( bytes: ByteArray, onComplete: Function = null )
		{
			super( bytes, WAVDecoder.parseHeader( bytes ), onComplete );
		}
	}
}