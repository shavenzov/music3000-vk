package com.audioengine.format.tasks
{
	import com.audioengine.core.AudioData;
	import com.audioengine.format.EncoderSettings;
	import com.audioengine.format.pcm.PCM16BitStereo44Khz;
	import com.audioengine.format.pcm.PCM32BitFloatStereo44Khz;
	import com.audioengine.format.pcm.PCMEncoder;
	import com.thread.BaseRunnable;
	
	import flash.utils.ByteArray;
	
	public class PCMEncoder extends BaseRunnable implements IEncoder
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
		private var encoder : com.audioengine.format.pcm.PCMEncoder;
		
		private var data : ByteArray;
		private var dataSize : uint;
		
		/**
		 * Кодированные данные 
		 */		
		private var _outputData : ByteArray;
		
		public function PCMEncoder()
		{
			super();
		}
		
		public function calcTotal( rawDataLength : int ) : int
		{
			return rawDataLength;
		}
		
		public function set rawData( value : ByteArray ) : void
		{
			_rawData = value;
			_total = calcTotal( _rawData.length );
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
		
		override public function process() : void
		{
			if ( _status == EncoderStatus.NONE )
			{
				encoder = new com.audioengine.format.pcm.PCMEncoder( /*new PCM16BitStereo44Khz()*/ new PCM32BitFloatStereo44Khz() );
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