package classes.api.events
{
	import flash.events.Event;
	
	public class PublisherEvent extends Event
	{
		public static const BEGIN     : String = 'BEGIN';
		//public static const PROCESSED : String = 'PROCESSED';
		public static const PUBLISHED : String = 'PUBLISHED';
		public static const END       : String = 'END';
		
		public var data : Object;
		
		public function PublisherEvent( type : String, data : Object = null )
		{
			super( type );
			this.data = data;
		}
		
		override public function clone():Event
		{
			return new PublisherEvent( type, data );
		}
	}
}