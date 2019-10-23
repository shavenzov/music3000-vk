package com.thread
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;

	public class SequencedThread extends Thread
	{
		private var _current         : int;
		private var _progress        : Number = 0.0;
		private var _currentProgress : Number = 0.0;
		
		public function SequencedThread(runnable:Object, msDelay:Number=33)
		{
			super(runnable, msDelay);
		}
		
		override protected function processor(e:TimerEvent):void {
			
			var r : IRunnable;
			var i : int = 0;
			
			totalTimesRan++;
			
			try
			{
				r = runnable[ _current ];
				
				
					r.process();
					
					if ( r.completed )
					{
						r.dispatchEvent( new Event( Event.COMPLETE, false, false ) );
						_current ++;
					}
					else if ( r.maxRunTimes != 0 && r.maxRunTimes == totalTimesRan ) 
					{
						r.error = true;
						r.dispatchEvent( new ErrorEvent(ErrorEvent.ERROR,false,false,"Thread ["  +r.name + "] " + 
							"timeout exceeded before IRunnable reported complete" ) );
					}	
					else
					{
						r.dispatchEvent( new ProgressEvent(ProgressEvent.PROGRESS,false,false,r.progress,r.total ) );
					}	
				
				
				if ( r.error )
				{
					_currentProgress = r.total;
					_current ++;
				}	
				else
				{
					_currentProgress = r.progress;
				}
				
				if ( r.completed || r.error )
				{
					_progress += _currentProgress;
					_currentProgress = 0;
				}	
				
			}
			catch( error : Error )
			{
				r.error = true;
				r.dispatchEvent( new ErrorEvent(ErrorEvent.ERROR,false,false,"Thread [" + r.name + "] encountered an error while" + 
					" calling the IRunnable.process() method: " + error.message ) );
			}
			
			if ( _progress == totalValue )
			{
				dispatchEvent( new Event( Event.COMPLETE, false, false ) );
				destroy();
			}
			else
			{	
				dispatchEvent( new ProgressEvent(ProgressEvent.PROGRESS,false,false, _progress + _currentProgress, totalValue ) );
			} 
		}
	}
}