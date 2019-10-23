package com.audioengine.format.wav
{
	import com.audioengine.format.pcm.PCM16BitStereo44Khz;

	/**
	 * @author Andre Michelle
	 */
	public final class WAV16BitStereo44Khz extends PCM16BitStereo44Khz
		implements IWAVIOStrategy
	{
		public static const INSTANCE: IWAVIOStrategy = new WAV16BitStereo44Khz();

		public function WAV16BitStereo44Khz()
		{
			super( [ 1, 65534 ] );
		}
	}
}
