package classes.api.events
{
	import classes.api.errors.APIError;
	
	import flash.events.Event;
	
	public class InviteFriendsEvent extends Event
	{
		public static const INVITE_FRIENDS  : String = 'INVITE_FRIENDS';
		public static const DO_USER_INVITED : String = 'DO_USER_INVITED';
		
		public static const PARAM_NAME : String = 'inviter_id';
		
		public var code : int;
		
		public function InviteFriendsEvent( type : String, code : int )
		{
			super(type);
			this.code = code;
		}
		
		public function get success() : Boolean
		{
			return code == APIError.OK;
		}
		
		override public function clone() : Event
		{
			return new InviteFriendsEvent( type, code );
		}
	}
}