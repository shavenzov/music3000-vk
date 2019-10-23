package com.audioengine.core.events
{
	import flash.events.Event;
	
	public class AudioDataEvent extends Event
	{
		public static const LENGTH_CHANGE : String = 'LENGTH_CHANGE';
		public static const BPM_CHANGE    : String = 'BPM_CHANGE'; 
		
		public function AudioDataEvent( type : String )
		{
			super( type );
		}
	}
}