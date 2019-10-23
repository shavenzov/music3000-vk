package components.controls.users.events
{
	import flash.events.Event;

	public class AutoScrollableEvent extends Event
	{
		
		//Когда генерируется событие STOPPED определяет в каком направление было движение до этого события
		public var direction : String;
		
		public function AutoScrollableEvent(type:String, direction : String = null )
		{
			super(type, false, false);
			this.direction = direction;
		}
		
		public static const MOVE_LEFT  : String = "onMoveLeft";
		public static const MOVE_RIGHT : String = "onMoveRight";
		public static const STOPPED    : String = "onStopped";
		
	}
}