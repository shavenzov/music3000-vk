package components.welcome.events
{
	import flash.events.Event;
	
	public class GoToEvent extends Event
	{
		public static const GO   : String = 'go';
		public static const BACK : String = 'back';
		
		//Куда переходить
		public var toIndex : int;
		public var toState : String;
		//Откуда переходим
		public var fromIndex : int;
		public var fromState : *;
		//Дополнительные произвольные данные передаваемые слайду
		public var other : *;
		
		
		public function GoToEvent( type:String, toIndex : int, toState : String, fromIndex : int = -2, fromState : * = -2, other : * = null )
		{
			super(type);
			this.toIndex = toIndex;
			this.toState = toState;
			this.fromIndex = fromIndex;
			this.fromState = fromState;
			this.other = other;
		}
		
		override public function clone():Event
		{
			return new GoToEvent( type, toIndex, toState, fromIndex, fromState, other );
		}
	}
}