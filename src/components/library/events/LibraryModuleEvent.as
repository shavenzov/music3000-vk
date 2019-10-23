package components.library.events
{
	import flash.events.Event;
	
	public class LibraryModuleEvent extends Event
	{
		public static const SEARCH_BOX_ENABLED_CHANGED : String = 'searchBoxEnabledChanged';
		
		public function LibraryModuleEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}