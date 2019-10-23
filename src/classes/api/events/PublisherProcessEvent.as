package classes.api.events
{
	import flash.events.Event;
	
	public class PublisherProcessEvent extends Event
	{
		public static const PROCESSED : String = 'PROCESS';
		
		public var url : String;
		
		public function PublisherProcessEvent( type : String, url : String )
		{
			super( type );
			
			this.url = url;
		}
		
		override public function clone() : Event
		{
			return new PublisherProcessEvent( type, url );
		}
	}
}