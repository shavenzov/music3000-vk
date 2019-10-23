package com.audioengine.format.tasks
{
	import com.audioengine.format.mpeg.id3v2.ID3v2;
	import com.thread.BaseRunnable;
	import com.thread.SimpleTask;
	
	import flash.utils.ByteArray;
	
	import cmodule.shine.CLibInit;
	
	public class ShineMp3Encoder extends BaseRunnable implements IEncoder
	{
		private static const WRITING_ID3_TAG : int = 10;
		
		private var _rawData    : ByteArray;
		private var _outputData : ByteArray; 
		
		private var _status : int = SimpleTask.NONE;
		private var _statusString : String = 'Кодирование';
		
		private var cshine:Object;
		
		private var id3Tags : Object;
		
		public function ShineMp3Encoder( id3Tags : Object = null )
		{
			super();
			this.id3Tags = id3Tags; 
		}
		
		public function get statusString():String
		{
			return _statusString;
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
			return _rawData;
		}
		
		public function set rawData(value:ByteArray):void
		{
		  _rawData = value;
		}
		
		public function calcTotal(rawDataLength:int):int
		{
			_total = rawDataLength;
			return _total;
		}
		
		public function clear():void
		{
		  cshine = null;
		}
		
		public function shineError(message:String):void {
			error = true;
			_statusString = _statusString + ' - ' + message;
			_status = EncoderStatus.ERROR;
		}
		
		private function updateProgress( percent : int ) : void
		{
			_progress = ( percent * _total ) / 100;
			//trace( _progress, _total, percent )
		}
		
		private function writeId3Tags() : void
		{
			var tags : ID3v2 = new ID3v2();
			
			for ( var tag : String in id3Tags )
			{
				tags.addTextFrame( tag, id3Tags[ tag ] );
			}
			
			_outputData = tags.getData();
		}
		
		private function initEncoder() : void
		{
			cshine = (new cmodule.shine.CLibInit).init();
			cshine.init( this, _rawData, _outputData );
			
			_status = EncoderStatus.CODING;
		}
		
		override public function process():void
		{
			if ( _status == EncoderStatus.NONE )
			{
				if ( id3Tags )
				{
					_status = WRITING_ID3_TAG;
					writeId3Tags();
				}
				else
				{
					_outputData = new ByteArray();
					initEncoder();	
				}
				
				return;
			}
			
			if ( _status == WRITING_ID3_TAG )
			{
				initEncoder();
				return;
			}
			
			if ( _status == EncoderStatus.CODING )
			{
				updateProgress( cshine.update() );
				
				if ( _progress == _total )
				{
					_status = SimpleTask.DONE;
					
					return;
				}
			}
		}
	}
}