package com.audioengine.format.aiff
{
	import com.thread.BaseRunnable;
	
	import flash.utils.ByteArray;
	
	public class AIFFThreadDecoder extends BaseRunnable
	{
		private var decoder : AIFFDecoder;
		
		private var _output      : ByteArray;
		private const _iteration   : int = 16384;
		
		public function AIFFThreadDecoder( data : ByteArray )
		{
			super();
			_name = 'WAVE Decoder';
			
			decoder = new AIFFDecoder( data );
			
			if ( ! decoder.supported )
			{
				throw new Error( 'Not supported AIFF format. ' + decoder.toString() );
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