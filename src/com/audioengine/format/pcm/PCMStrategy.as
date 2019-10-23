package com.audioengine.format.pcm
{
	import com.audioengine.format.FormatInfo;
	/**
	 * @author Andre Michelle
	 */
	public class PCMStrategy
	{
		private var _compressionType: Object;
		private var _samplingRate: Number;
		private var _numChannels: uint;
		private var _bits: uint;
        
		/**
		 * Коэффициент усиления/ослабления 
		 */		
		protected var _gain : Number = 1.0;
		
		public function PCMStrategy( compressionType: Object, samplingRate: Number, numChannels: uint, bits: uint )
		{
			_compressionType = compressionType;
			_samplingRate = samplingRate;
			_numChannels = numChannels;
			_bits = bits;
		}
        
		public final function get gain() : Number
		{
			return _gain;
		}
		
		public final function set gain( value : Number ) : void
		{
			_gain = value;
		}
		
		private function compressionSupports( compression : Object ) : Boolean
		{
			if ( _compressionType is Array )
			{
				for each( var type : * in _compressionType )
				{
					if ( type == compression )
					{
						return true;
					}
				}
			}
			
			return compression == _compressionType;
		}
		
		final public function supports( info: FormatInfo ): Boolean
		{
			return  _samplingRate == info.samplingRate && _numChannels == info.numChannels && _bits == info.bits && compressionSupports( info.compressionType );
		}

		final public function get compressionType(): Object
		{
			return _compressionType;
		}

		final public function get samplingRate(): Number
		{
			return _samplingRate;
		}

		final public function get numChannels(): uint
		{
			return _numChannels;
		}

		final public function get bits(): uint
		{
			return _bits;
		}
		
		final public function get blockAlign(): uint
		{
			return ( _numChannels * _bits ) >> 3;
		}
	}
}