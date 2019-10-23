package classes.api.events
{
	import flash.events.Event;
	
	public class AMFEvent extends Event
	{
		public static const BEGIN_LOADING : String = 'beginLoading';
		public static const END_LOADING   : String = 'endLoading';
		
		public function AMFEvent( type : String )
		{
			super( type );
		}
		
		override public function clone() : Event
		{
			return new AMFEvent( type );
		}
	}
}