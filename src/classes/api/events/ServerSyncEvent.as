package classes.api.events
{
	import flash.events.Event;
	
	public class ServerSyncEvent extends Event
	{
		public static var SYNC : String = 'sync';
		
		public function ServerSyncEvent( type : String )
		{
			super( type );
		}
	}
}