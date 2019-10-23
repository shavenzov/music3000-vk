/**
 * Менеджер задач, позволяющий использовать "псевдо-потоки" для обработки задач 
 */
package com.thread
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Dispatched when the thread's work is done
	 * 
	 * @eventType   flash.events.Event.COMPLETE
	 */ 
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * Dispatched when the thread's work (IRunnable) makes progress
	 * 
	 * @eventType   flash.events.ErrorEvent.ERROR
	 */ 
	[Event(name="progress", type="flash.events.ProgressEvent")]    
	
	/**
	 * <p>This class simulates a thread in ActionScript </p>
	 * 
	 * <p>You create a PsuedoThread by passing an IRunnable
	 * who's process() function will be called every "msDelay" milliseconds.
	 * The IRunnable's isComplete() method is consulted
	 * after each process() invocation to determine if the processing
	 * should cease. If the IRunnable is NOT completed (and the thread's timeout has not been reached)
	 * PsuedoThread will dispatch ProgressEvents using the progress values retrieved
	 * from IRunnable.getProgress() and IRunnable.getTotal(). 
	 * When IRunnable.isComplete() returns true the Thread will terminate and 
	 * fire off the Event.COMPLETE event. </p>
	 * 
	 * <p>PseudoThreads are useful for time consuming processing operations
	 * where a delay in the UI is un-acceptable. The smaller you set the <code>msDelay</code>
	 * setting, the faster this thread will execute and subsequently other parts of your application
	 * will be less responsive (noteably a GUI).</p>
	 * 
	 * <p>Note! To prevent memory leaks in your application callers must always remember 
	 * to de-register for the complete event from this thread after it has been received
	 *  (as well as the progress and error events!)</p>
	 * 
	 * <P>Caller can also specify the max amount of time this Thread should run before it will 
	 *      stop processing and throw an Error. This is done via the <code>msTimeout</code> constructor
	 * argument. If no timeout is specified the process will run forever.</P>
	 * 
	 * 
	 * */
	public class Thread extends EventDispatcher {
		
		// the timer which is the core of our PseudoThread
		private var intTimer:Timer;
		
		// total times we have ran
		protected var totalTimesRan:int = 0;
		
		/**
		 * Сумма значений total IRunnable 
		 */		
		protected var totalValue : Number = 0.0;
		
		// the IRunnable we are processing
		protected var runnable : Vector.<IRunnable>;
		
		/**
		 * Constructor. 
		 * 
		 * @param       runnable                        The IRunnable that this thread will process. The IRunnable's process()
		 *                                                              method will be called repeatably by this thread.
		 * 
		 * 
		 * @param       msDelay                         delay between each thread "execution" call of IRunnable.process(), in milliseconds
		 * 
		 * 
		 * */
		public function Thread( runnable : Object,  msDelay : Number = 33 ) {
			
			if ( runnable as IRunnable )
			{
			  this.runnable = Vector.<IRunnable>( [ runnable ] );	
			}
			else if ( runnable as Vector.<IRunnable> )
			{
			  this.runnable = Vector.<IRunnable>( runnable );
			}
			else throw new Error( 'First parameter of Thread constructor, must have IRunnable or Vector.<IRunnable> type' );	
			
			var i : int = 0;
			
			while ( i < this.runnable.length )
			{
				if ( this.runnable[ i ].timeOut != -1 )
				{
					if ( msDelay > this.runnable[ i ].timeOut )
					{
						throw new Error( "Thread cannot be constructed with a" + this.runnable[ i ].name + ".timeOut that is less than the msDelay" );
					}
					
					this.runnable[ i ].maxRunTimes = Math.ceil( this.runnable[ i ].timeOut / msDelay );
				}
				
				totalValue += this.runnable[ i ].total;
				
				i ++;
			}	
			
			intTimer = new Timer( msDelay );
			intTimer.addEventListener(TimerEvent.TIMER,processor);
		}
		
		
		
		/** 
		 * Destroys this and deregisters from the Timer event
		 * */
		public function destroy():void {
			intTimer.stop();
			intTimer.removeEventListener(TimerEvent.TIMER,processor);
			runnable = null;
			intTimer = null;
		}
		
		/**
		 * Called each time our internal Timer executes. Here we call the runnable's process() function 
		 * and then check the IRunnable's state to see if we are done. If we are done we dispatch a complete
		 * event. If progress is made we dispatch progress, lastly on error, this will destroy itself 
		 * and dispatch an ErrorEvent.<BR><BR>
		 * 
		 * Note that an ErrorEvent will be thrown if a timeout was specified and we have reached it without
		 * the IRunnable reporting isComplete() within the timeout period.
		 * 
		 * @throws ErrorEvent when the process() method encounters an error or if the timeout is reached.
		 * @param       e TimerEvent
		 * */
		protected function processor(e:TimerEvent):void {
			
			var r : IRunnable;
			var i : int = 0;
			var progress : Number = 0.0;
			
			totalTimesRan++;
			
			try
			{
				while( i < runnable.length )
				{
					r = runnable[ i ];
					
					if ( ! r.completed && ! r.error )
					{
						r.process();
						
						if ( r.completed )
						{
							if ( r.hasEventListener( Event.COMPLETE ) )
							{
								r.dispatchEvent( new Event( Event.COMPLETE, false, false ) );	
							}
						}
						else if ( r.maxRunTimes != 0 && r.maxRunTimes == totalTimesRan ) 
						{
							r.error = true;
							sendError( r, new ErrorEvent(ErrorEvent.ERROR,false,false,"Thread ["  +r.name + "] " + 
								"timeout exceeded before IRunnable reported complete" ) );
						}	
						else
						{
							if ( r.hasEventListener( ProgressEvent.PROGRESS ) )
							{
								r.dispatchEvent( new ProgressEvent(ProgressEvent.PROGRESS,false,false,r.progress,r.total ) );	
							}
						}	
					}
					
					if ( r.error )
					{
						progress += r.total;
					}	
					else
					{
						progress += r.progress;
					}	
					
					i ++;
				}	
		      }
			catch( error : Error )
			{
				r.error = true;
				sendError( r, new ErrorEvent(ErrorEvent.ERROR, false, false, error.message, error.errorID ) );
			}
			
			if ( progress == totalValue )
			{
			  dispatchEvent( new Event( Event.COMPLETE, false, false ) );
			  destroy();
			}
			else
			{	
			  dispatchEvent( new ProgressEvent(ProgressEvent.PROGRESS,false,false, progress, totalValue ) );
			} 
		}
		
		private function sendError( r : IRunnable, e : ErrorEvent ) : void
		{
			dispatchEvent( e );
			
			if ( r.hasEventListener( e.type ) )
			{
				dispatchEvent( e );
			}	
		}
		
		/**
		 * This method should be called when the thread is to start running and calling
		 * it's IRunnable's process() method until work is finished.
		 * 
		 * */
		public function start():void {
			intTimer.start(); 
		}
		
		/**
		 * Приостанавливает выполнение списка задач 
		 * 
		 */		
		public function suspend() : void
		{
			intTimer.stop();
		}
		
	}

}