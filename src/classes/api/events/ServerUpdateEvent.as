package classes.api.events
{
	import flash.events.Event;
	
	public class ServerUpdateEvent extends Event
	{
		public static const START_UPDATE : String = 'START_UPDATE';
		public static const END_UPDATE   : String = 'END_UPDATE';
		
		public var end : Date;
		public var reason : String;
		
		public function ServerUpdateEvent( type:String, end : Date = null, reason : String = null )
		{
			super( type );
			this.end = end;
			this.reason = reason;
		}
		
		override public function clone() : Event
		{
			return new ServerUpdateEvent( type, end, reason );
		}
	}
}