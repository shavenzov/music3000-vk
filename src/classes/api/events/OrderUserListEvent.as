package classes.api.events
{
	import flash.events.Event;
	
	public class OrderUserListEvent extends Event
	{
		public static const ORDER_USER_LIST : String = 'ORDER_USER_LIST';
		
		public var orderedList : Array;
		
		public function OrderUserListEvent( type : String, orderedList : Array )
		{
			super( type );
			this.orderedList = orderedList;
		}
		
		override public function clone():Event
		{
			return new OrderUserListEvent( type, orderedList );
		}
	}
}