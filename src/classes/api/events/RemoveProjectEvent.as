package classes.api.events
{
	import flash.events.Event;
	
	public class RemoveProjectEvent extends Event
	{
		public static const REMOVE : String = 'REMOVE';
		
		public function RemoveProjectEvent(type:String)
		{
			super(type);
		}
	}
}