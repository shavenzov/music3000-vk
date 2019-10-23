package components.sequencer.events
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public class StartDraggingEvent extends MouseEvent
	{
		public var source                : Object;
		public var trackChangedInitEvent : MouseEvent;
		
		public function StartDraggingEvent(type:String, source : Object, trackChangedInitEvent : MouseEvent = null, localX:Number=NaN, localY:Number=NaN )
		{
			super(type, false, false, localX, localY );
			this.source = source;
			this.trackChangedInitEvent = trackChangedInitEvent;
		}
		
		public function getLocalX( stageX : Number ) : Number
		{	
			if ( source )
			{
			  return source.parent.globalToLocal( new Point( stageX, 0 ) ).x;	
			}
			
			return NaN;
		}	
	}
}