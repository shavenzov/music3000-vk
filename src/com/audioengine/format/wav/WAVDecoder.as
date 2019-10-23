package com.audioengine.format.wav
{
	import com.audioengine.format.FormatError;
	import com.audioengine.format.FormatInfo;
	import com.audioengine.format.pcm.IPCMIOStrategy;
	import com.audioengine.format.pcm.PCMDecoder;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.IDataInput;

	/**
	 * @author Andre Michelle
	 */
	public final class WAVDecoder extends PCMDecoder
	{
		public static function parseHeader( bytes: ByteArray ): FormatInfo
		{
			bytes.position = 0;
			bytes.endian = Endian.LITTLE_ENDIAN;

			if ( bytes.readUnsignedInt() != WAVTags.RIFF )
				throw FormatError.TAG_MISMATCH;

			const fileSize : int = bytes.readUnsignedInt();

			if ( bytes.length != fileSize + 8 )
			{
				// Length does not match to wav-specifications
				// I have seen a wav with less before, but worked anyway
				// Skip
			}

			if ( bytes.readUnsignedInt() != WAVTags.WAVE )
				throw FormatError.TAG_MISMATCH;

			var chunkID : uint;
			var chunkLength : uint;
			var chunkPosition : uint;
			
			var compressionType: Object;
			var numChannels: uint;
			var samplingRate: Number;
			var bits: uint;
			var blockAlign: uint;
			var dataOffset: uint;
			var dataLength: uint;

			while( 8 <= bytes.bytesAvailable ) // Had a wav with a dead byte at the end (skip)
			{
				chunkID = bytes.readUnsignedInt();
				chunkLength = bytes.readUnsignedInt();
				chunkPosition = bytes.position;

				switch( chunkID )
				{
					case WAVTags.FMT:
						compressionType = bytes.readUnsignedShort();
						numChannels = bytes.readUnsignedShort();
						samplingRate = bytes.readUnsignedInt();
						bytes.readUnsignedInt(); // bytesPerSecond (redundant)
						blockAlign = bytes.readUnsignedShort();
						bits = bytes.readUnsignedShort();
						// WAV allows additional information here (skip)
						break;
						
					case WAVTags.DATA:
						// Audio data chunk starts here (skip)
						dataOffset = chunkPosition;
						dataLength = chunkLength;
						break;

					default:
						// WAV allows additional tags to store extra information like markers (skip)
						break;
				}

				// Skip
				bytes.position = chunkPosition + chunkLength;
				
				if ( chunkLength == 0 )
				{
					break;
				}
			}
			
			return new FormatInfo( compressionType, samplingRate, numChannels, bits, dataLength / blockAlign, dataOffset );
		}
		
		private static const STRATEGIES : Vector.<IWAVIOStrategy> = getSupportedStrategies();

		/*
		 * You can add extra strategies here.
		 * 
		 * Lowest index: Most expected
		 * Highest index: Less expected
		 */
		private static function getSupportedStrategies() : Vector.<IWAVIOStrategy>
		{
			const strategies: Vector.<IWAVIOStrategy> = new Vector.<IWAVIOStrategy>( 10, true );

			strategies[0] = WAV16BitStereo44Khz.INSTANCE;
			strategies[1] = WAV16BitMono44Khz.INSTANCE;
			strategies[2] = WAV32BitStereo44Khz.INSTANCE;
			strategies[3] = WAV32BitMono44Khz.INSTANCE;
			strategies[4] = WAV24BitStereo44Khz.INSTANCE;
			strategies[5] = WAV24BitMono44Khz.INSTANCE;
			strategies[6] = WAV32BitIntStereo44Khz.INSTANCE;
			strategies[7] = WAV32BitIntMono44Khz.INSTANCE; 
			strategies[8] = WAV8BitStereo44Khz.INSTANCE;
			strategies[9] = WAV8BitMono44Khz.INSTANCE;
			
			return strategies;
		}
		
		private var _header: FormatInfo;

		public function WAVDecoder( bytes: ByteArray )
		{
			super( bytes, evaluateHeader( bytes ) );
		}
		
		override public function get numSamples(): Number
		{
			return _header.numSamples;
		}
		
		override public function get dataOffset(): Number
		{
			return _header.dataOffset;
		}
		
		override public function get blockAlign(): int
		{
			return _header.blockAlign;
		}

		private function evaluateHeader( bytes: ByteArray ) : IPCMIOStrategy
		{
			_header = parseHeader( bytes );
			trace( _header );
			const n : int = STRATEGIES.length;

			for( var i: int = 0 ; i < n ; ++i )
			{
				var strategy: IWAVIOStrategy = STRATEGIES[i];
				
				if ( strategy.supports( _header ) )
				{
					return strategy;
				}
			}
			
			return null;
		}
		
		override public function toString():String
		{
			return _header.toString();
		}
	}
}