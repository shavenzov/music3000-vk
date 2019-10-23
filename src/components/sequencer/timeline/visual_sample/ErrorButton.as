package components.sequencer.timeline.visual_sample
{
	import components.Base;
	
	import flash.events.MouseEvent;
	
	[Embed(source="/assets/assets.swf", symbol="error_sample_icon")]
	public class ErrorButton extends Base
	{
		public function ErrorButton()
		{
			super();
			alpha = 0.75;
			
			addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
			addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
		}
		
		private function onMouseOver( e : MouseEvent ) : void
		{
			alpha = 1; 	
		}
		
		private function onMouseOut( e : MouseEvent ) : void
		{
			alpha = 0.75;
		}
		
		override protected function measure():void
		{
			contentWidth  = 17.5;
			contentHeight = 17.5;
		}
	}
}