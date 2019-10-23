package com.audioengine.format.wav
{
	import com.audioengine.format.pcm.PCM16BitMono44Khz;

	/**
	 * @author Andre Michelle
	 */
	public final class WAV16BitMono44Khz extends PCM16BitMono44Khz
		implements IWAVIOStrategy
	{
		public static const INSTANCE: IWAVIOStrategy = new WAV16BitMono44Khz();

		public function WAV16BitMono44Khz()
		{
			super( [ 1, 65534 ] );
		}
	}
}