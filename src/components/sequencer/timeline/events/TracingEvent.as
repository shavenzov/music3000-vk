package components.sequencer.timeline.events
{
	import flash.events.Event;
	import flash.geom.Point;
	
	public class TracingEvent extends Event
	{
		public static const START_TRACING : String = 'START_TRACING';
		public static const STOP_TRACING  : String = 'STOP_TRACING';
		
		public static const START_MOVING  : String = 'START_MOVING';
		public static const STOP_MOVING   : String = 'STOP_MOVING';
		
		/**
		 * Отслеживать ли движение по оси х 
		 */		
		public var xAxis : Boolean;
		
		/**
		 * Отслеживать ли движение по оси у 
		 */		
		public var yAxis : Boolean;
		
		/**
		 * Смещение по осям 
		 */		
		public var offset : Point;
		
		/**
		 * Посылать ли объекту сгенерировавшему это событие START_MOVING и STOP_MOVING  
		 */		
		public var notify : Boolean;
		
		/**
		 * Использовать отступ во время перемещения 
		 */		
		public var gapThenMoving : Boolean;
		
		public function TracingEvent( type : String, xAxis : Boolean = true, yAxis : Boolean = true, offset : Point = null, notify : Boolean = false, gapThenMoving : Boolean = true )
		{
			super( type, false, false );
			
			this.xAxis   = xAxis;
			this.yAxis   = yAxis;
			this.offset  = offset;
			this.notify  = notify;
			this.gapThenMoving = gapThenMoving;
		}
	}
}