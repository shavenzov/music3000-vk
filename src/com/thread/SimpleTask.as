package com.thread
{
	import com.thread.events.TaskEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	
	public class SimpleTask extends EventDispatcher
	{
		private static const TIMEOUT : Number = 50.0;
		
		/**
		 * Произошла ошибка 
		 */		
		public static const ERROR : int = -10;
		
		public static const NONE : int = 0;
		
		public static const DONE : int = 10000;
		
		protected var _status : int = NONE;
		
		public function SimpleTask()
		{
			super();
		}
		
		public function get status() : int
		{
			return _status;
		}
		
		public function run() : void
		{
			next();
		}
		
		protected function next() : void
		{
			dispatchEvent( new Event( Event.CHANGE ) );
		}
		
		protected function callLater( func : Function, ...params ) : void
		{
			params.unshift( func, TIMEOUT );
			
			setTimeout.apply( this, params );
		}
		
		private var _loading : Boolean;
		
		public function get loading() : Boolean
		{
			return _loading;
		}
		
		protected function operationStart() : void
		{
			_loading = true;
			dispatchEvent( new TaskEvent( TaskEvent.START ) );
		}
		
		protected function operationComplete() : void
		{
			_loading = false;
			dispatchEvent( new TaskEvent( TaskEvent.COMPLETE ) );
		}
	}
}