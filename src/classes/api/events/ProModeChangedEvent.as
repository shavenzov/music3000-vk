package classes.api.events
{
	import flash.events.Event;
	
	public class ProModeChangedEvent extends Event
	{
		public static const PRO_EXPIRED   : String = 'pro_expired';
		public static const PRO_ACTIVATED : String = 'pro_activated';
		
		public function ProModeChangedEvent(type:String)
		{
			super(type);
		}
	}
}