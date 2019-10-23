package components.controls.events
{
	import flash.events.Event;
	
	public class SearchtextInputEvent extends Event
	{
		public static const RESET : String = 'RESET';
		
		public function SearchtextInputEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}