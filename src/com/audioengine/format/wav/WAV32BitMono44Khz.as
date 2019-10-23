package com.audioengine.format.wav
{
	import com.audioengine.format.pcm.PCM32BitFloatMono44Khz;

	/**
	 * @author Andre Michelle
	 */
	public final class WAV32BitMono44Khz extends PCM32BitFloatMono44Khz
		implements IWAVIOStrategy
	{
		public static const INSTANCE: IWAVIOStrategy = new WAV32BitMono44Khz();

		public function WAV32BitMono44Khz()
		{
			super( 3 );
		}
	}
}