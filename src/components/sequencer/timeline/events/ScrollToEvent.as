/**
 * Событие символизирующее о том, что неплохо было-бы прокрутить timeline, так чтобы отобразить 
 * указанный поинт указанным способом 
 */
package components.sequencer.timeline.events
{
	import flash.events.Event;
	
	public class ScrollToEvent extends Event
	{
		public static const SCROLL_TO : String = 'SCROLL_TO';
		
		/**
		 * До какой точки прокрутить 
		 */		
		public var pos : Number;
		
		/**
		 * Каким методом 
		 */		
		public var scrollMode : int;
		
		/**
		 * Дополнительный произвольный параметр 
		 */		
		public var param : Number;
		
		public function ScrollToEvent(type:String, pos : Number, scrollMode : int, param : Number = 0 )
		{
			super( type, false, false );
			this.pos        = pos;
			this.scrollMode = scrollMode;
			this.param      = param;
		}
	}
}