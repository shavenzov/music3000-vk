package components.welcome.events
{
	import flash.events.Event;
	
	public class BrowseProjectsEvent extends Event
	{
		public static const BROWSE_PROJECTS : String = 'browseProjects';
		
		public var selectedUser : Object;
		
		public function BrowseProjectsEvent(type:String, selectedUser : Object)
		{
			super(type);
			this.selectedUser = selectedUser;
		}
		
		override public function clone():Event
		{
			return new BrowseProjectsEvent( type, selectedUser );
		}
	}
}