package components.controls
{
	import components.sequencer.timeline.visual_sample.Indicator;
	
	import mx.core.UIComponent;
	
	public class ProgressIndicator extends UIComponent
	{
		private var indicator : components.sequencer.timeline.visual_sample.Indicator;
		
		private var _progress : Number;
		private var _total    : Number;
		
		public function ProgressIndicator()
		{
			super();
		}
		
		public function get progress() : Number
		{
			return _progress;
		}
		
		public function set progress( value : Number ) : void
		{
			_progress = value;
			invalidateProperties();
		}
		
		public function get total() : Number
		{
		  return _total;
		}
		
		public function set total( value : Number ) : void
		{
			_total = value;
			invalidateProperties();
		}
		
		override protected function createChildren() : void
		{
			super.createChildren();
			
			indicator = new components.sequencer.timeline.visual_sample.Indicator();
			addChild( indicator );
		}
		
		override protected function commitProperties():void
		{
			indicator.progress.gotoAndStop( Math.round( _progress * 100 / _total ) );
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			indicator.width  = unscaledWidth;
			indicator.height = unscaledHeight; 
		}
	}
}