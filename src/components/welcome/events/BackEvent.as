package components.welcome.events
{
	import flash.events.Event;
	
	public class BackEvent extends Event
	{
		public static const BACK : String = 'back';
		
		public function BackEvent(type:String)
		{
			super(type);
		}
	}
}