package components.welcome.events
{
	import classes.api.data.ProjectInfo;
	
	import flash.events.Event;
	
	public class OpenProjectEvent extends Event
	{
		public static const OPEN : String = 'open';
		
		public var info : ProjectInfo;
		public var fromIndex : int;
		public var fromState : String;
		
		public function OpenProjectEvent( type : String, info : ProjectInfo, fromIndex : int = -1, fromState : String = null )
		{
			super(type);
			this.info = info;
			this.fromIndex = fromIndex;
			this.fromState = fromState;
		}
		
		override public function clone():Event
		{
			return new OpenProjectEvent( type, info, fromIndex, fromState );
		}
	}
}