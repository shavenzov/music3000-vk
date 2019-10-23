package classes.api.events
{
	import flash.events.Event;
	
	import classes.api.data.UserInfo;
	import classes.api.errors.APIError;
	
	public class GetUserInfoEvent extends Event
	{
		public static const GET_USER_INFO : String = 'GET_USER_INFO';
		
		public var info  : UserInfo;
		public var error : int; 
		
		public function GetUserInfoEvent( type : String, info : UserInfo, error : int )
		{
			super( type );
			
			this.info  = info;
			this.error = error;
		}
		
		public function get isError() : Boolean
		{
			return error != APIError.OK;
		}
		
		override public function clone():Event
		{
			return new GetUserInfoEvent( type, info, error );
		}
	}
}