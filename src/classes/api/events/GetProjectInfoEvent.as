package classes.api.events
{
	import flash.events.Event;
	
	import classes.api.data.ProjectInfo;
	import classes.api.errors.APIError;
	
	public class GetProjectInfoEvent extends Event
	{
		public static const GET_PROJECT_INFO : String = 'GET_PROJECT_INFO';
		
		public var info  : ProjectInfo;
		public var error : int;
		
		public function GetProjectInfoEvent( type : String, info : ProjectInfo, error : int )
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
			return new GetProjectInfoEvent( type, info, error );
		}
	}
}