package classes.api.events
{
	import classes.api.errors.APIError;
	
	import flash.events.Event;
	
	public class ProjectNameEvent extends Event
	{
		public static const DEFAULT_PROJECT_NAME : String = 'DEFAULT_PROJECT_NAME';
		public static const RESOLVE_NAME : String = 'RESOLVE_NAME';
		
		public var name : String;
		public var errorCode : int;
		
		public function ProjectNameEvent(type:String, name : String, errorCode : int )
		{
			super(type);
			this.name = name;
			this.errorCode = errorCode;
		}
		
		public function get error() : Boolean
		{
			return errorCode != APIError.OK;
		}
		
		override public function clone() : Event
		{
			return new ProjectNameEvent( type, name, errorCode );
		}
	}
}