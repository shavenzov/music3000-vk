package com.audioengine.format.wav
{
	import com.audioengine.format.pcm.PCM32BitIntMono44Khz;

	public final class WAV32BitIntMono44Khz extends PCM32BitIntMono44Khz
		implements IWAVIOStrategy
	{
		public static const INSTANCE: IWAVIOStrategy = new WAV32BitIntMono44Khz();
		
		public function WAV32BitIntMono44Khz()
		{
			super( [ 1, 65534 ] );
		}
	}
}