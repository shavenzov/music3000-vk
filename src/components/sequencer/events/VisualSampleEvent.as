package components.sequencer.events
{
	import flash.display.InteractiveObject;
	import flash.events.MouseEvent;
	
	public class VisualSampleEvent extends MouseEvent
	{
		public static const RESIZE_TO_LEFT_MOUSE_DOWN  : String = 'RESIZE_TO_LEFT_MOUSE_DOWN';
		public static const RESIZE_TO_RIGHT_MOUSE_DOWN : String = 'RESIZE_TO_RIGHT_MOUSE_DOWN';
		public static const START_DRAGGING             : String = 'START_DRAGGING';
		public static const STOP_DRAGGING              : String = 'STOP_DRAGGING';
		public static const TRACK_CHANGED_DRAGGING     : String = 'TRACK_CHANGED_DRAGGING';
		
		public function VisualSampleEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false, localX:Number=NaN, localY:Number=NaN, relatedObject:InteractiveObject=null, ctrlKey:Boolean=false, altKey:Boolean=false, shiftKey:Boolean=false, buttonDown:Boolean=false, delta:int=0)
		{
			super(type, bubbles, cancelable, localX, localY, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta);
		}
	}
}