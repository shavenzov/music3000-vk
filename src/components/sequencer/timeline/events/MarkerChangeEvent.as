package components.sequencer.timeline.events
{
	import flash.events.Event;
	
	public class MarkerChangeEvent extends Event
	{
		public static const MARKER_POSITION_CHANGED             : String = 'MARKER_POSITION_CHANGED';
		
		public static const PLAYHEAD_POSITION_CHANGED           : String = 'PLAYHEAD_POSITION_CHANGED';
		
		public static const LEFT_LOOP_BORDER_POSITION_CHANGED   : String = 'LEFT_LOOP_BORDER_POSITION_CHANGED';
		public static const RIGHT_LOOP_BORDER_POSITION_CHANGED  : String = 'RIGHT_LOOP_BORDER_POSITION_CHANGED';
		
		public static const LOOP_CHANGED_ON  : String = 'LOOP_CHANGED_ON';
		public static const LOOP_CHANGED_OFF : String = 'LOOP_CHANGED_OFF';
		public static const START_LOOP_EDITING : String = 'START_LOOP_EDITING';
		public static const END_LOOP_EDITING : String = 'END_LOOP_EDITING';
		
		public static const DURATION_POSITION_CHANGED : String = 'DURATION_POSITION_CHANGED';
		
		public var pos  : Number;
		
		public function MarkerChangeEvent( type:String, pos : Number )
		{
			super(type, false, false);
			this.pos  = pos;
		}
		
		override public function clone():Event
		{
			return new MarkerChangeEvent( type, pos );
		}	
	}
}