package classes.tasks.mixdown.events
{
	import flash.events.Event;
	
	public class MixdownOptionsEvent extends Event
	{
		public static const SELECTED : String = 'selected';
		
		public var params : Object;
		
		public function MixdownOptionsEvent( type:String, params : Object )
		{
			super( type );
			this.params = params;
		}
		
		override public function clone() : Event
		{
			return new MixdownOptionsEvent( type, params );
		}
	}
}