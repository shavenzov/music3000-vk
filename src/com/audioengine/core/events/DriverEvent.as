package com.audioengine.core.events
{
	import flash.events.Event;

	public class DriverEvent extends Event
	{
		public static const AFTER_PROCESSING  : String = 'AFTER_PROCESSING';
		public static const BEFORE_PROCESSING : String = 'BEFORE_PROCESSING';
		
		public function DriverEvent( type : String )
		{
			super( type );
		}	
	}
}