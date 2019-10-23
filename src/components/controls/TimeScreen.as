package components.controls
{
	import flash.events.Event;
	import flash.filters.BlurFilter;
	
	import mx.core.UIComponent;
	
	import classes.events.ChangeBPMEvent;
	
	import components.controls.timeScreenClasses.TempoDisplay;
	import components.controls.timeScreenClasses.TimeDisplay;
	import components.controls.timeScreenClasses.events.DisplayEvent;
	
	[Event(type="flash.events.Event", name="BPM_CHANGED")]
	[Event(type="classes.events.ChangeBPMEvent", name="BPM_COMPLETE_CHANGE")]
	[Event(type="flash.events.Event", name="VIEW_TYPE_CHANGED")]
	public class TimeScreen extends UIComponent
	{
		private static const BG_COLOR : uint = 0x171717;
		
		private static const TOP_PADDING : Number = 0;
		private static const BOTTOM_PADDING : Number = 0;
		
		private var time  : TimeDisplay;
		private var tempo : TempoDisplay;
		
		public function TimeScreen()
		{
			super();
		}
		
		public function get position() : Number
		{
			return time.position;
		}
		
		public function set position( value : Number ) : void
		{
			time.position = value;
		}
		
		public function get bpm() : Number
		{
			return tempo.bpm;
		}
		
		public function set bpm( value : Number ) : void
		{
			tempo.bpm = value;
			time.bpm  = value;
		}
		
		public function get timeInMeasures() : Boolean
		{
			return time.inMeasures;
		}
		
		public function set timeInMeasures( value : Boolean ) : void
		{
			time.inMeasures = value;
		}
		
		private function onViewTypeChanged( e : Event ) : void
		{
			dispatchEvent( e );
		}
		
		private function onBPMChanged( e : Event ) : void
		{
			time.bpm = tempo.bpm;
		    dispatchEvent( e );
		}
		
		private function onBPMCompleteChange( e : Event ) : void
		{
			dispatchEvent( e );
		}
		
		override protected function createChildren():void
		{
			time  = new TimeDisplay();
			time.addEventListener( DisplayEvent.VIEW_TYPE_CHANGED, onViewTypeChanged );
			
			tempo = new TempoDisplay();
			tempo.addEventListener( DisplayEvent.BPM_CHANGED, onBPMChanged );
			tempo.addEventListener( DisplayEvent.BPM_COMPLETE_CHANGE, onBPMCompleteChange );
			
			addChild( time );
			addChild( tempo );
			
			filters = [
				        //new DropShadowFilter( 3 ),
						//new BevelFilter( 6, 248, 0xffffff, 1.0, 0x666666, 1.0, 32, 32, 0.32 ),
						new BlurFilter( 2, 2 )
				      ];
		}
		
		override protected function measure() : void
		{
			measuredWidth = time.measuredWidth + tempo.measuredWidth + 16;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			time.setActualSize( time.measuredWidth, time.measuredHeight );
			tempo.setActualSize( tempo.measuredWidth, tempo.measuredHeight );
			
			time.x = 8;
			time.y = ( unscaledHeight - time.height ) / 2;
			tempo.move( time.x + time.width, time.y );
			
			graphics.clear();
			graphics.lineStyle( 1, BG_COLOR, 0.5 );
			graphics.drawRect( 0, 0, unscaledWidth, unscaledHeight );
		}
	}
}