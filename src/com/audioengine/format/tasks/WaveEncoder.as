package com.audioengine.format.tasks
{
	import com.audioengine.core.AudioData;
	import com.audioengine.format.EncoderSettings;
	import com.audioengine.format.wav.IWAVIOStrategy;
	import com.audioengine.format.wav.WAV16BitStereo44Khz;
	import com.audioengine.format.wav.WAV24BitStereo44Khz;
	import com.audioengine.format.wav.WAV32BitStereo44Khz;
	import com.audioengine.format.wav.WAVEncoder;
	import com.thread.BaseRunnable;
	
	import flash.utils.ByteArray;
	
	public class WaveEncoder extends BaseRunnable implements IEncoder
	{
		private static const bytesPerChunk : int = EncoderSettings.BYTES_PER_CHUNK;
		
		/**
		 * Исходные данные 
		 */		
		private var _rawData : ByteArray;
		
		/**
		 * Текущий статус выполнения 
		 */		
		private var _status : int = EncoderStatus.NONE;
		
		/**
		 * Кодер 
		 */		
		private var encoder : WAVEncoder;
		
		private var data : ByteArray;
		private var dataSize : uint;
		
		/**
		 * Кодированные данные 
		 */		
		private var _outputData : ByteArray;
		
		/**
		 * Качество исходного WAVE файла 16/24/32 бита 
		 */		
		private var _bits : uint;
		
		/**
		 * Нормалайзер для определения коэффициента усиления/ослабления 
		 */		
		private var normalizer : Normalizer;
		
		public function WaveEncoder( bits : uint = 16, normalizer : Normalizer = null )
		{
			super();
			_bits = bits;
			this.normalizer = normalizer;
		}
		
		public function calcTotal( rawDataLength : int ) : int
		{
			_total = rawDataLength;
			return _total;
		}
		
		public function set rawData( value : ByteArray ) : void
		{
			_rawData = value;
		}
		
		public function get rawData() : ByteArray
		{
			return _rawData;
		}
		
		public function get outputData() : ByteArray
		{
			return _outputData;
		}
		
		public function get status() : int
		{
			return _status;
		}
		
		public function get statusString() : String
		{
			return 'Кодирование';
		}
		
		public function clear() : void
		{
		}
		
		private function getEncoderStrategy() : IWAVIOStrategy
		{
			var encoder : IWAVIOStrategy;
			
			switch ( _bits )
			{
			  case 16 : encoder = new WAV16BitStereo44Khz(); break;
			  case 24 : encoder = new WAV24BitStereo44Khz(); break;
			  case 32 : encoder = new WAV32BitStereo44Khz(); break;
			  default : throw new Error( _bits + 'bits not supported wave format.' );	  
			}
			
			if ( normalizer )
			{
				encoder.gain = normalizer.gain;
			}
			
			return encoder;
		}
		
		override public function process() : void
		{
			if ( _status == EncoderStatus.NONE )
			{
				encoder = new WAVEncoder( getEncoderStrategy() );
				data = new ByteArray();
				_progress = 0;
				
				_status = EncoderStatus.CODING;
			}
			
			if ( _status == EncoderStatus.CODING )
			{
				
					dataSize = Math.min( _rawData.length - _progress, bytesPerChunk );
					data.position = 0;
					data.writeBytes( _rawData, _progress, dataSize );
					data.position = 0;
					encoder.write32BitStereo44KHz( data, AudioData.bytesToFrames( dataSize ) );
					
					_progress += dataSize;
					
					if ( _progress == _rawData.length )
					{
						_outputData = encoder.bytes;
						encoder = null;
						data.clear();
						data = null;
						_status = EncoderStatus.DONE;
					}
			}
		}
	}
}