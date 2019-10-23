package components.sequencer.timeline.events
{
	import flash.events.Event;
	
	public class TrackerEvent extends Event
	{
		public static const START_SAMPLE_DRAGGING      : String = 'START_SAMPLE_DRAGGING';
		public static const STOP_SAMPLE_DRAGGING       : String = 'STOP_SAMPLE_DRAGGING';
		public static const VIRTUAL_NUM_TRACKS_CHANGED : String = 'VIRTUAL_NUM_TRACKS_CHANGED'; 
		
		public var numTracksToShow : int;
		public var maxNumTracksToShow : int;
		
		public function TrackerEvent(type:String, numTracksToShow : int = 0, maxNumTracksToShow : int = 0 )
		{
			super( type );
			this.numTracksToShow = numTracksToShow;
			this.maxNumTracksToShow = maxNumTracksToShow;
		}
	}
}