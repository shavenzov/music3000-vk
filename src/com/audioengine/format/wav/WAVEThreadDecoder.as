package com.audioengine.format.wav
{
	import com.thread.BaseRunnable;
	
	import flash.utils.ByteArray;
	
	public class WAVEThreadDecoder extends BaseRunnable
	{
		private var decoder : WAVDecoder;
		
		private var _output      : ByteArray;
		private const _iteration   : int = 32 * 1024;
		
		public function WAVEThreadDecoder( data : ByteArray )
		{
			super();
			_name = 'WAVE Decoder';
			
			decoder = new WAVDecoder( data );
			
			if ( ! decoder.supported )
			{
				throw new Error( 'Not supported WAVE format. ' + decoder.toString() );
			}
			
			_output = new ByteArray();
			_total = decoder.numSamples;
			
			trace( 'format detected', decoder.toString() );
		}
		
		override public function process():void
		{
			var l : Number = Math.min( _total - _progress, _iteration );
			
			decoder.extract( _output, l, _progress );
			
			//trace( _progress, _total, _iteration );
			
			_progress += l;
		}
		
		public function get output() : ByteArray
		{
			return _output;
		}
	}
}