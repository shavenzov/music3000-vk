package components.sequencer.timeline.events
{
	public class MarkerEvent
	{
		public static const MARKER_PRESS   : String = 'MARKER_PRESS';
		public static const MARKER_RELEASE : String = 'MARKER_RELEASE';
		
		public static const PLAYHEAD_PRESS : String = 'PLAYHEAD_PRESS';
		public static const PLAYHEAD_RELEASE : String = 'PLAYHEAD_RELEASE';
		
		public static const DURATION_PRESS : String = 'DURATION_PRESS';
		public static const DURATION_RELEASE : String = 'DURATION_RELEASE';
		
		public static const LEFT_LOOP_BORDER_PRESS : String = 'LEFT_LOOP_BORDER_PRESS';
		public static const LEFT_LOOP_BORDER_RELEASE : String = 'LEFT_LOOP_BORDER_RELEASE';
		
		public static const RIGHT_LOOP_BORDER_PRESS : String = 'RIGHT_LOOP_BORDER_PRESS';
		public static const RIGHT_LOOP_BORDER_RELEASE : String = 'RIGHT_LOOP_BORDER_RELEASE';
		
		public static const LOOP_MARKER_PRESS : String = 'LOOP_MARKER_PRESS';
		public static const LOOP_MARKER_RELEASE : String = 'LOOP_MARKER_RELEASE';
	}
}