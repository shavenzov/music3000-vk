package classes.api.events
{
	import classes.api.errors.APIError;
	
	import flash.events.Event;
	
	public class SwitchedOnProModeEvent extends Event
	{
		public static const SWITCHED_ON : String = 'switched_on';
		
		public var errorCode : int;
		
		public function SwitchedOnProModeEvent( type : String, errorCode : int )
		{
			super( type );
			this.errorCode = errorCode;
		}
		
		public function get error() : Boolean
		{
			return errorCode != APIError.OK;
		}
		
		override public function clone() : Event
		{
			return new SwitchedOnProModeEvent( type, errorCode );
		}
	}
}