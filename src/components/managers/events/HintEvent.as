package components.managers.events
{
	import flash.events.Event;
	
	public class HintEvent extends Event
	{
		public static const HIDE : String = 'hide';
		
		public function HintEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}