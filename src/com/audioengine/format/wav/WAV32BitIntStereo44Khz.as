package com.audioengine.format.wav
{
	import com.audioengine.format.pcm.PCM32BitIntStereo44Khz;

	public final class WAV32BitIntStereo44Khz extends PCM32BitIntStereo44Khz
		implements IWAVIOStrategy
	{
		public static const INSTANCE: IWAVIOStrategy = new WAV32BitIntStereo44Khz();
		
		public function WAV32BitIntStereo44Khz()
		{
			super( [ 1, 65534 ] );
		}
	}
}