package com.thread.events
{
	import flash.events.Event;
	
	public class TaskEvent extends Event
	{
		public static const START : String = 'START';
		public static const COMPLETE : String = 'COMPLETE';
		
		public function TaskEvent( type : String )
		{
			super( type );
		}
		
		override public function clone() : Event
		{
			return new TaskEvent( type );
		}
	}
}