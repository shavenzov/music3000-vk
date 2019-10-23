package classes.api.events
{
	import flash.events.Event;
	
	import classes.api.errors.APIError;
	
	public class GetProjectEvent extends Event
	{
		public static const GET_PROJECT : String = 'GET_PROJECT';
		
		public var data  : String;
		public var error : int;
		
		public function GetProjectEvent( type : String, data : String, error : int )
		{
			super( type );
			
			this.data  = data;
			this.error = error;
		}
		
		public function get isError() : Boolean
		{
			return error != APIError.OK;
		}
		
		override public function clone() : Event
		{
			return new GetProjectEvent( type, data, error );
		}
	}
}