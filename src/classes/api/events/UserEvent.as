package classes.api.events
{
	import classes.api.data.UserInfo;
	import classes.api.errors.APIError;
	
	import flash.events.Event;
	
	public class UserEvent extends Event
	{
		public static const CONNECT  : String = 'USER_CONNECT';
		public static const REGISTER : String = 'USER_REGISTER';
		public static const UPDATE   : String = 'USER_UPDATE';
		
		public var userInfo     : UserInfo;
		public var lastUserInfo : UserInfo;
		public var errorCode    : int; 
		
		public function UserEvent( type : String, userInfo  : UserInfo = null, lastUserInfo : UserInfo = null, errorCode : int = APIError.OK )
		{
			super(type);
			
			this.errorCode    = errorCode; 
			this.userInfo     = userInfo;
			this.lastUserInfo = lastUserInfo;
		}
		
		public function get moneyIncremented() : Boolean
		{
			return lastUserInfo ? ( userInfo.money > lastUserInfo.money ) : false;
		}
		
		public function get moneyAdded() : int
		{
			return lastUserInfo ? userInfo.money - lastUserInfo.money : 0;
		}
		
		public function get error() : Boolean
		{
			return errorCode != APIError.OK;
		}
		
		override public function clone():Event
		{
			return new UserEvent( type, userInfo, lastUserInfo, errorCode );
		}
	}
}