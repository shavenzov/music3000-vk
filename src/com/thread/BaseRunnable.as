/**
 * Базовый класс всех задач, реализует часть интерфейса IRunnable 
 */
package com.thread
{
	import flash.events.EventDispatcher;

	public class BaseRunnable extends EventDispatcher implements IRunnable
	{
		private var _error       : Boolean;
		private var _maxRunTimes : int = 0;
		
		protected var _name : String = 'DefaultRunnable';
		protected var _timeOut : int;
		
		protected var _total : Number = 0.0;
		protected var _progress : Number = 0.0;
		
		public function BaseRunnable( timeOut : int = -1 )
		{
		  this._timeOut = timeOut;
		}
		
		public function process() : void
		{
			
		}
		
		public function get completed() : Boolean
		{
			return _total == _progress;
		}
		
		public function get total() : Number
		{
		  return _total;	
		}
		
		public function get progress() : Number
		{
			return _progress;
		}
		
		public function get name() : String
		{
			return _name;
		}	
			
		public function set name( value : String ) : void
		{
			_name = value;
		}
		
		public function get timeOut() : Number
		{
			return _timeOut;
		}
		
		public function get maxRunTimes() : int
		{
			return _maxRunTimes;
		}	
		
		public function set maxRunTimes( value : int ) : void
		{
			_maxRunTimes = value;
		}
		
		public function get error() : Boolean
		{
			return _error;
		}	
		
		public function set error( value : Boolean ) : void
		{
			_error = value;
		}	
		
	}
}