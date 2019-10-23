package classes.api.events
{
	import classes.api.errors.APIError;
	
	import flash.events.Event;
	
	public class SaveProjectEvent extends Event
	{
		public static const SAVE   : String = 'SAVE';
		public static const UPDATE : String = 'UPDATE';
		
		public var id : int;
		
		public function SaveProjectEvent( type:String, id : int )
		{
			super( type );
			this.id    = id;
		}
		
		public function get error() : Boolean
		{
			return id < APIError.OK;
		}
		
		public function get errorCode() : int
		{
			if ( error ) return id;
			return APIError.OK;
		}
		
		override public function clone():Event
		{
			return new SaveProjectEvent( type, id );
		}
		
	}
}