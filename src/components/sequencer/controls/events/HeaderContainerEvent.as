package components.sequencer.controls.events
{
	import flash.events.Event;
	
	public class HeaderContainerEvent extends Event
	{
		public static const START_CHANGING : String = 'START_CHANGING';
		public static const CHANGED : String = 'CHANGED';
		
		public var text : String;
		
		public function HeaderContainerEvent( type : String, text : String )
		{
			super( type );
			
			this.text = text;
		}
		
		override public function clone():Event
		{
			return new HeaderContainerEvent( type, text );
		}	
	}
}