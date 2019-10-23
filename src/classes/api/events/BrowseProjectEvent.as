package classes.api.events
{
	import flash.events.Event;
	
	public class BrowseProjectEvent extends Event
	{
		public static const BROWSE_PROJECTS : String = 'BROWSE_PROJECT';
		public static const BROWSE_EXAMPLES : String = 'BROWSE_EXAMPLES';
		
		public var projects : Array;
		
		public function BrowseProjectEvent( type : String, projects : Array )
		{
			super( type );
			this.projects = projects;
		}
		
		override public function clone():Event
		{
			return new BrowseProjectEvent( type, projects );
		}
	}
}