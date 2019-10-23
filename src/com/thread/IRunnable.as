package com.thread
{
	import flash.events.IEventDispatcher;

	public interface IRunnable extends IEventDispatcher
	{
		/**
		 * Called repeatedly by Thread until
		 * a timeout is reached or isComplete() returns true.
		 * Implementors should implement their functioning
		 * code that does actual work within this method
		 *
		* */
		function process() : void;
		
		/**
		 * Called by PseudoThread after each successful call
		 * to process(). Once this returns true, the thread will
	     * stop.
		 *
		 * @return  boolean true/false if the work is done and no further
		 *          calls to process() should be made
		* */
		function get completed() : Boolean;
		
		/**
		  * Returns an int which represents the total
		  * amount of "work" to be done.
		  *
		  * @return  int total amount of work to be done
		* */
		function get total() : Number;
		
		/**
		  * Returns an int which represents the total amount
		  * of work processed so far out of the overall total
		  * returned by getTotal()
		  *
		  * @return  int total amount of work processed so far
		* */
		function get progress() : Number;
		
		/**
		 * The name of task 
		 * @return 
		 * 
		 */		
		function get name() : String;
		function set name( value : String ) : void
		
		/**
		 * Maximum process task time 
		 * @return 
		 * 
		 */			
		function get timeOut() : Number
		
		/**
		 * Максимальное количество вызовов метода process, расчитывается исходя timeOut и интервала между вызовами метода process
		 * Устанавливается классом Threads
		 * @return 
		 * 
		 */			
		function get maxRunTimes() : int
		function set maxRunTimes( value : int ) : void
		
		/**
		 * Указывает, что выполнение задачи завершилось ошибкой
		 * Устанавливается классом Threads 
		 * @return 
		 * 
		 */		
		function get error() : Boolean
		function set error( value : Boolean ) : void
		 	
			
	}
}