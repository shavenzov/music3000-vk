package components.sequencer.timeline.events
{
	import components.sequencer.events.VisualSampleEvent;
	import components.sequencer.timeline.visual_sample.BaseVisualSample;
	
	import flash.events.Event;
	
	public class SelectionSampleEvent extends Event
	{
		public static const CHANGE : String = 'CHANGE';
		
		public var selected : Vector.<BaseVisualSample>;
		
		public function SelectionSampleEvent( type : String, selected :  Vector.<BaseVisualSample> )
		{
			super(type);
			this.selected = selected;
		}
		
		override public function clone():Event
		{
			return new SelectionSampleEvent( type, selected );
		}
	}
}