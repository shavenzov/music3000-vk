package components.managers.events
{
	import flash.events.Event;
	
	import mx.core.IFlexDisplayObject;
	
	public class PopUpEvent extends Event
	{
		public static const OPEN  : String = 'open';
		public static const CLOSE : String = 'close';
		
		/**
		 * Общщее количество открытых окон 
		 */		
		public var numWindows : uint;
		
		/**
		 * Текущее окно с которым происходит какое-либо действие 
		 */		
		public var window : IFlexDisplayObject;
		
		public function PopUpEvent( type : String, numWindows : uint, window : IFlexDisplayObject )
		{
			super( type );
			this.numWindows = numWindows;
			this.window = window;
		}
		
		override public function clone():Event
		{
			return new PopUpEvent( type, numWindows, window );
		}
	}
}