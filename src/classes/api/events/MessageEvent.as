package classes.api.events
{
	import flash.events.Event;
	
	public class MessageEvent extends Event
	{
		public static const MESSAGE : String = 'message';
		
		/**
		 * Массив сообщений
		 * [0].type
		 * [0].message
		 */		
		public var messages : Array;
		
		public function MessageEvent( type : String, messages : Array )
		{
			super(type);
			this.messages = messages;
		}
		
		override public function clone() : Event
		{
			return new MessageEvent( type, messages );
		}
	}
}