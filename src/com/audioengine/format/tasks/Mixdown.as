package com.audioengine.format.tasks
{
	import com.audioengine.calculations.Calculation;
	import com.audioengine.core.AudioData;
	import com.thread.BaseRunnable;
	
	import flash.utils.ByteArray;
	
	import classes.SequencerImplementation;
	
	public class Mixdown extends BaseRunnable implements IEncoder
	{
		/**
		 * Размер буфера для иморта проекта в аудиофайл ( в фреймах ) 
		 */		
		private static const MIXDOWN_BUFFER_SIZE : uint = AudioData.framesToBytes( Calculation.MAX_DATA_WIDTH );
		
		private var seq : SequencerImplementation;
		
		private var _outputData : ByteArray = new ByteArray();
		
		/**
		 * Текущий статус выполнения 
		 */		
		private var _status : int = EncoderStatus.NONE;
		
		private var data : ByteArray = new ByteArray();
		private var dataLength : uint;
		
		public function Mixdown( seq : SequencerImplementation, from : Number, to : Number )
		{
			super();
			this.seq = seq;
			
			_total = seq.beginMixDown( from, to );
			_status = EncoderStatus.MIXDOWNING;
		}
		
		public function get statusString():String
		{
			return 'Сведение';
		}
		
		public function get status():int
		{
			return _status;
		}
		
		public function get outputData():ByteArray
		{
			return _outputData;
		}
		
		public function get rawData():ByteArray
		{
			return null;
		}
		
		public function set rawData(value:ByteArray):void
		{
		}
		
		public function calcTotal(rawDataLength:int):int
		{
			return _total;
		}
		
		public function clear():void
		{
			if ( seq.mixdowning )
			{
			  seq.endMixdown();
			}
		}
		
		/**
		 * Количество вызовов mixdown за один process 
		 */		
		private static const numMixdownPerOperations : int = 5;
		
		override public function process():void
		{
		  if ( _status == EncoderStatus.MIXDOWNING )
		  {
			  var i : int = 0;
			  
			  do
			  {
				  mixdown();
				  i ++;
			  }
			  while( ( _status == EncoderStatus.MIXDOWNING ) && ( i < numMixdownPerOperations ) ) 
		  }
		}
		
		private function mixdown() : void
		{
			dataLength = Math.min( _total - _outputData.length, MIXDOWN_BUFFER_SIZE );
			data.length = dataLength;
			
			try
			{	
				seq.mixdown( data, dataLength );	
			}
			catch( e : Error )
			{	
				seq.endMixdown();
				_status = EncoderStatus.ERROR;
				error = true;
				throw e;
			}
			
			_outputData.writeBytes( data );
			
			if ( _outputData.length == _total )
			{
				seq.endMixdown();
				
				data.clear();
				data = null;
				_status = EncoderStatus.DONE;
			}
			
			_progress = _outputData.length;
		}
	}
}